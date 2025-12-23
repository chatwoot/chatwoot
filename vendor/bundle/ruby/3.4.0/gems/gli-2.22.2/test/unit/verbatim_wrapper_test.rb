require_relative "test_helper"

class TerminalTest < Minitest::Test
  include TestHelper

  def test_handles_nil
    @wrapper = GLI::Commands::HelpModules::VerbatimWrapper.new(rand(100),rand(100))
    @result = @wrapper.wrap(nil)
    assert_equal '',@result
  end

  def test_does_not_touch_input
    @wrapper = GLI::Commands::HelpModules::VerbatimWrapper.new(rand(100),rand(100))
    @input = <<EOS
      |This is|an ASCII|table|
      +-------+--------+-----+
      | foo   |  bar   | baz |
      +-------+--------+-----+
EOS
    @result = @wrapper.wrap(@input)
    assert_equal @input,@result
  end

end
