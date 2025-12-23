require_relative "test_helper"
require "open3"

class GLIPoweredAppTest < Minitest::Test
  include TestHelper

  def teardown
    FileUtils.rm_f("todo.rdoc")
  end

  def test_help_works
    out = run_app("help")
    assert_top_level_help(out)
  end

  def test_unknown_command_exits_nonzero
    out, err, status = run_app("asdfasdfasdf", expect_failure: true, return_err_and_status: true)
    assert_match /Unknown command 'asdfasdfasdf'/,err
    assert_equal 64, status.exitstatus
    assert_top_level_help(out)
  end

  def test_unknown_switch_exits_nonzero
    out, err, status = run_app("list --foo", expect_failure: true, return_err_and_status: true)
    assert_match /Unknown option \-\-foo/,err
    assert_equal 64, status.exitstatus
    assert_match /COMMAND OPTIONS/, out
  end

  def test_missing_args_exits_nonzero
    out, err, status = run_app("list", expect_failure: true, return_err_and_status: true)
    assert_match /list requires these options: required_flag, required_flag2/,err
    assert_equal 64, status.exitstatus
    assert_match /COMMAND OPTIONS/, out
  end

  def test_doc_generation
    out, err, status = run_app("_doc", return_err_and_status: true)
    assert File.exist?("todo.rdoc")
  end

private
  def assert_top_level_help(out)
    assert_match /SYNOPSIS/, out
    assert_match /GLOBAL OPTIONS/, out
    assert_match /COMMANDS/, out
  end

  def run_app(args="", return_err_and_status: false, expect_failure: false)
    run_command("test/apps/todo/bin/todo",args,return_err_and_status:return_err_and_status,expect_failure:expect_failure)
  end
end
