require "minitest/autorun"
require "pathname"
require "fileutils"

# Copied from https://github.com/splattael/minitest-around
# so as to avoid an explicit dependency
Minitest::Test.class_eval do
  alias_method :run_without_around, :run
  def run(*args)
    if defined?(around)
      result = nil
      around { result = run_without_around(*args) }
      result
    else
      run_without_around(*args)
    end
  end
end

module TestHelper
  def around(&block)
    Bundler.with_original_env do
      root = Pathname(__FILE__).dirname / ".." / ".."
      FileUtils.chdir root do
        block.()
      end
    end
  end

  def run_gli(args="", return_err_and_status: false, expect_failure: false)
    run_command("bin/gli",args,return_err_and_status:return_err_and_status,expect_failure:expect_failure)
  end

  def run_command(command,args,return_err_and_status:,expect_failure:,rubylib:nil)
    command_line_invocation = "#{command} #{args}"
    env = {}
    if !rubylib.nil?
      env["RUBYLIB"] = rubylib
    end
    stdout_string, stderr_string, status = Open3.capture3(env,command_line_invocation)
    if expect_failure
      refute_equal 0,status.exitstatus,"Expected failure for '#{command_line_invocation}' but it succeeded"
    else
      assert_equal 0,status.exitstatus,"Expected success for '#{command_line_invocation}' but it failed:\n#{stdout_string}\n\n#{stderr_string}\n\n"
    end
    if return_err_and_status
      [ stdout_string, stderr_string, status ]
    else
      stdout_string
    end
  end
end
