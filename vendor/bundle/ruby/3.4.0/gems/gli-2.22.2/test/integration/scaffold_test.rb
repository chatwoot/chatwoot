require_relative "test_helper"
require "open3"

class ScaffoldCommandTest < Minitest::Test
  include TestHelper

  def test_scaffolded_app_has_reasonable_setup
    FileUtils.rm_rf "scaffold_test"
    run_gli("init scaffold_test")
    assert Dir.exist? "scaffold_test"
    FileUtils.chdir "scaffold_test" do
      run_command("bundle install", "", return_err_and_status: false, expect_failure: false)

      scaffold_lib = "lib:../lib"

      # help works
      out = run_command("bin/scaffold_test","--help", return_err_and_status: false, expect_failure: false, rubylib: scaffold_lib)
      assert_match /SYNOPSIS/,out
      assert_match /GLOBAL OPTIONS/,out
      assert_match /COMMANDS/,out

      # can run unit tests
      out = run_command("bundle exec ","rake test", return_err_and_status: false, expect_failure: false, rubylib: scaffold_lib)
      assert_match /0 failures/,out
      assert_match /0 errors/,out
      assert_match /0 skips/,out
    end
  end

end
