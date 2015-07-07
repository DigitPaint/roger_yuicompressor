require File.dirname(__FILE__) + "/../../lib/roger_yuicompressor/processor"
require "test/unit"
require "rspec/mocks/standalone"

class ProcessorTest < Test::Unit::TestCase
  include RSpec::Mocks::ExampleMethods
  
  def setup
    @processor = RogerYuicompressor::Yuicompressor.new
    @tmp_file  = 'file.css'    

    # TEMP file creation
    File.open(@tmp_file, 'w') do |tmp_file|
      tmp_file.write('.selector { background: green; }')
    end
  end

  # Just make sure we're dealing with the correct class
  def test_setup
    assert_kind_of(RogerYuicompressor::Yuicompressor, @processor, "Not initialized the correct class.")
  end

  # When no suffix is given, there is no suffix and 
  # this default behaviour should be valid
  def test_default_valid_suffix
    assert(@processor.valid_suffix?, "The given suffix (#{@processor.options[:suffix]}) is not valid.")
  end

  # When the suffix '.min' is given it should be valid
  def test_valid_suffix
    assert(@processor.valid_suffix?(".min"), "Suffix '.min' should be valid.")
    assert(@processor.valid_suffix?("-test"), "Suffix '-test' should be valid.")    
  end

  # Test that extension of file get correct extracted
  def test_extracting_extension
    assert_equal('rb', @processor.get_file_type('file.rb'))
    assert_equal('js', @processor.get_file_type('file.min.js'))
    assert_equal('css', @processor.get_file_type('file.css'))
    assert_not_equal('min.js', @processor.get_file_type('file.min.js'))
  end
  
  # Test default behaviour that minfied data is put in the original file
  def test_default_behaviour_processor_minify
    assert_equal('file.css', @processor.minify_file(@tmp_file, nil))
  end

  def test_behaviour_processor_minify
    processor = RogerYuicompressor::Yuicompressor.new({:suffix => '.min'})
    assert_equal('file.min.css', processor.minify_file(@tmp_file, nil))
    
    assert(File.exists?('file.min.css'))
    assert(File.exists?('file.css'))
  end

  def test_call_method
    options = {:suffix => '.testsuffix', :match => ["file.css"]}
    processor = RogerYuicompressor::Yuicompressor.new(options)
    
    # Mock
    release = double('Roger::Release')

    # Expectations
    expect(release).to receive(:log)
    expect(release).to receive(:debug)
    expect(release).to receive(:get_files).with(processor.options[:match], processor.options[:skip]).and_return(processor.options[:match])

    # Call method
    processor.call(release)

    assert(File.exists?('file.testsuffix.css'), "File 'file.testsuffix.css' doesn't exist using Processor::Call method")
    assert(File.exists?('file.css'), "File 'file.css' doesn't exist using Processor::Call method")
  end

  def teardown
    Dir['file.*.css', 'file.css'].each do |file|
      File.delete(file)
    end
  end
end
