require 'roger/release'
require 'yui/compressor'

module RogerYuicompressor
  class Yuicompressor < ::Roger::Release::Processors::Base

    attr_reader :options

    def initialize(options={})
      @options = {
        :match => ["**/*.{css,js}"],
        :skip =>  [/javascripts\/vendor\/.*\.js\Z/, /_doc\/.*/],
        :delimiter => Regexp.escape("/* -------------------------------------------------------------------------------- */"),
        :suffix => nil
      }.update(options)

      compressor_options = {:line_break => 80}
      @css_compressor = YUI::CssCompressor.new(compressor_options) 
      @js_compressor = YUI::JavaScriptCompressor.new(compressor_options)      
    end
    
    # Compresses all JS and CSS files, it will keep all lines before
    # 
    #     /* -------------------------------------------------------------------------------- */
    # 
    # (80 dashes)
    #
    # @options options [Array] match Files to match, default to ["**/*.{css,js}"]
    # @options options [Regexp] :delimiter An array of header delimiters. Defaults to the one above. The delimiter will be removed from the output.
    # @options options [Array[Regexp]] :skip An array of file regular expressions to specifiy which files to skip. Defaults to [/javascripts\/vendor\/.\*.js\Z/, /_doc\/.*/]
    # @options options [Nil|string] :suffix A string that will be added to the filename of the minified file, if set to nil will overwrite the existing file. Defaults to nil.
    #   (example: test.js => test.min.js where :suffix => '.min').
    def call(release, options={})
      @options.update(options)
            
      release.log self,  "Minifying #{@options[:match].inspect}"

      raise(RuntimeError, "The given suffix #{@options[:suffix]} is invalid.") unless valid_suffix?(@options[:suffix])
            
      # Add version numbers and minify the files
      release.get_files(@options[:match], @options[:skip]).each do |filename|
        minify_file(filename, release)
      end
    end

    # Retrieve the type of the file (based on extension)
    # 
    # @param [String] The name of the file incl. extension
    def get_file_type(filename)
      filename[/\.([^.]+)\Z/, 1]
    end

    # Check if a valid suffix is given
    def valid_suffix?(suffix = nil)
      suffix === nil || suffix.kind_of?(String)
    end

    # Read and minfiy the given file
    def minify_file(file, release)
      data = File.read(file);
      type = get_file_type(file)

      if @options[:suffix] != nil
        output_file = file.sub(".#{type}", "") + @options[:suffix] + ".#{type}"
      else
        output_file = file
      end

      File.open(output_file, "w") do |fh| 
        
        # Extract header and store for later use
        header = data[/\A(.+?)\n#{options[:delimiter]}\s*\n/m,1]
        minified = [header]
  
        # Actual minification
        # release.debug self,  "Minifying #{file}"
        case type
        when "css"
          minified << @css_compressor.compress(data)
        when "js"
          minified << @js_compressor.compress(data)
        else
          # release.warn self, "Error minifying: encountered unknown type \"#{type}\""
          minified << data
        end

        fh.write minified.join("\n")
      end      

      output_file
    end

  end
end

::Roger::Release::Processors.register(:yuicompressor, RogerYuicompressor::Yuicompressor)