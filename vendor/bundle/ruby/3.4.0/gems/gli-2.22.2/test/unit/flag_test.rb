require_relative "test_helper"

class FlagTest < Minitest::Test
  include TestHelper

  def test_basics_simple
    setup_for_flag_with_names(:f)
    assert_attributes_set
    assert_equal(:f,@cli_option.name)
    assert_nil @cli_option.aliases
  end

  def test_basics_kinda_complex
    setup_for_flag_with_names([:f])
    assert_attributes_set
    assert_equal(:f,@cli_option.name)
    assert_nil @cli_option.aliases
  end

  def test_basics_complex
    setup_for_flag_with_names([:f,:file,:filename])
    assert_attributes_set
    assert_equal(:f,@cli_option.name)
    assert_equal [:file,:filename], @cli_option.aliases
    assert_equal ["-f VAL","--file VAL","--filename VAL",/foobar/,Float],@flag.arguments_for_option_parser
  end

  def test_flag_can_mask_its_value
    setup_for_flag_with_names(:password, :mask => true)
    assert_attributes_set(:safe_default_value => "********")
  end

  def setup_for_flag_with_names(names,options = {})
      @options = {
        :desc => 'Filename',
        :long_desc => 'The Filename',
        :arg_name => 'file',
        :default_value => '~/.blah.rc',
        :safe_default_value => '~/.blah.rc',
        :must_match => /foobar/,
        :type => Float,
      }.merge(options)
      @flag = GLI::Flag.new(names,@options)
      @cli_option = @flag
  end

  def assert_attributes_set(override={})
      expected = @options.merge(override)
      assert_equal(expected[:desc],@flag.description)
      assert_equal(expected[:long_desc],@flag.long_description)
      assert_equal(expected[:default_value],@flag.default_value)
      assert_equal(expected[:safe_default_value],@flag.safe_default_value)
      assert_equal(expected[:must_match],@flag.must_match)
      assert_equal(expected[:type],@flag.type)
  end
end
