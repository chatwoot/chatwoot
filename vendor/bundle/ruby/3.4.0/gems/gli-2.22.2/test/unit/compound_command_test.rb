require_relative "test_helper"

class CompoundCommandFinderTest < Minitest::Test
  include TestHelper

  def test_exception_for_missing_commands
    @name = "new"
    @unknown_name = "create"
    @existing_command = OpenStruct.new(:name => @name)
    @base = OpenStruct.new( :commands => { @name => @existing_command })

    @code = lambda { GLI::Commands::CompoundCommand.new(@base,{:foo => [@name,@unknown_name]}) }

    ex = assert_raises(RuntimeError,&@code)
    assert_match /#{Regexp.escape(@unknown_name)}/,ex.message
  end
end
