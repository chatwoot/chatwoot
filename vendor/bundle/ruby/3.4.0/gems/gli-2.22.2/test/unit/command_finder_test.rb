require_relative "test_helper"

class CommandFinderTest < Minitest::Test
  include TestHelper

  def setup
    @app = CLIApp.new
    [:status, :deployable, :some_command, :some_similar_command].each do |command|
      @app.commands[command] = GLI::Command.new(:names => command)
    end
  end

  def teardown
  end

  def test_unknown_command_name
    assert_raises(GLI::UnknownCommand) do
      GLI::CommandFinder.new(@app.commands, :default_command => :status).find_command(:unfindable_command)
    end
  end

  def test_no_command_name_without_default
    assert_raises(GLI::UnknownCommand) do
      GLI::CommandFinder.new(@app.commands).find_command(nil)
    end
  end

  def test_no_command_name_with_default
    actual = GLI::CommandFinder.new(@app.commands, :default_command => :status).find_command(nil)
    expected = @app.commands[:status]

    assert_equal(actual, expected)
  end

  def test_ambigous_command
    assert_raises(GLI::AmbiguousCommand) do
      GLI::CommandFinder.new(@app.commands, :default_command => :status).find_command(:some)
    end
  end

  def test_partial_name_with_autocorrect_enabled
    actual = GLI::CommandFinder.new(@app.commands, :default_command => :status).find_command(:deploy)
    expected = @app.commands[:deployable]

    assert_equal(actual, expected)
  end

  def test_partial_name_with_autocorrect_disabled
    assert_raises(GLI::UnknownCommand) do
      GLI::CommandFinder.new(@app.commands, :default_command => :status, :autocomplete => false)
        .find_command(:deploy)
    end
  end
end
