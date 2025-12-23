require_relative "test_helper"
require "open3"

class GLICLITest < Minitest::Test
  include TestHelper

  class AppHelp < GLICLITest
    def test_running_with_no_options_produces_help
      out = run_gli
      assert_output_looks_like_help out
    end

    def test_running_with_help_command_produces_help
      out = run_gli("help")
      assert_output_looks_like_help out
    end

    def test_running_with_help_switch_produces_help
      out = run_gli("--help")
      assert_output_looks_like_help out
    end

  private

    def assert_output_looks_like_help(out)
      assert_match /gli - create scaffolding for a GLI-powered application/,out
      assert_match /SYNOPSIS/,out
      assert_match /GLOBAL OPTIONS/,out
      assert_match /COMMANDS/,out
    end

  end

  class Scaffolding < GLICLITest
    def test_help_on_scaffold_command
      out = run_gli("help scaffold")
      assert_output_looks_like_help(out)
    end
    def test_help_on_scaffold_command_as_init
      out = run_gli("help init")
      assert_output_looks_like_help(out)
    end

  private

    def assert_output_looks_like_help(out)
      assert_match /init - Create a new GLI-based project/,out
      assert_match /SYNOPSIS/,out
      assert_match /COMMAND OPTIONS/,out
    end
  end

private

  def run_gli(args="", return_err_and_status: false, expect_failure: false)
    command_line_invocation = "bin/gli #{args}"
    stdout_string, stderr_string, status = Open3.capture3(command_line_invocation)
    if expect_failure
      refute_equal 0,status.exitstatus,"Expected failure for '#{command_line_invocation}' but it succeeded"
    else
      assert_equal 0,status.exitstatus,"Expected success for '#{command_line_invocation}' but it failed"
    end
    if return_err_and_status
      [ stdout_string, stderr_string, status ]
    else
      stdout_string
    end
  end
end
