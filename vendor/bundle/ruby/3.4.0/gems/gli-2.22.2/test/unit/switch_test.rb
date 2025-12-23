require_relative "test_helper"

class SwitchTest < Minitest::Test
  include TestHelper

  def test_basics_simple
    switch_with_names(:filename)
    attributes_should_be_set
    assert_equal(:filename,@cli_option.name)
    assert_nil @cli_option.aliases
  end

  def test_basics_kinda_complex
    switch_with_names([:f])
    attributes_should_be_set
    assert_equal(:f,@cli_option.name)
    assert_nil @cli_option.aliases
  end

  def test_basics_complex
    switch_with_names([:f,:file,:filename])
    attributes_should_be_set
    assert_equal(:f,@cli_option.name)
    assert_equal([:file,:filename],@cli_option.aliases)
    assert_equal ["-f","--[no-]file","--[no-]filename"],@switch.arguments_for_option_parser
  end

  def test_includes_negatable
    assert_equal '-a',GLI::Switch.name_as_string('a')
    assert_equal '--[no-]foo',GLI::Switch.name_as_string('foo')
  end

private 

  def switch_with_names(names)
    @options = {
      :desc => 'Filename',
      :long_desc => 'The Filename',
    }
    @switch = GLI::Switch.new(names,@options)
    @cli_option = @switch
  end

  def attributes_should_be_set
    assert_equal(@options[:desc],@switch.description)
    assert_equal(@options[:long_desc],@switch.long_description)
  end

end
