require "minitest/autorun"

begin
  require "hoe"
rescue LoadError => e
  warn e.message
  return
end

require "minitest/test_task"

Hoe.load_plugins # make sure Hoe::Test is loaded

class TestHoeTest < Minitest::Test
  PATH = "test/minitest/test_minitest_test_task.rb"

  def util_cmd_string *prelude_framework
    mt_path = %w[lib test .].join File::PATH_SEPARATOR
    mt_expected = "-I%s -w -e '%srequire %p' -- "

    mt_expected % [mt_path, prelude_framework.join("; "), PATH]
  end

  def util_exp_cmd
    @tester.make_test_cmd.sub(/ -- .+/, " -- ")
  end

  def test_make_test_cmd_for_minitest
    skip "Using TESTOPTS... skipping" if ENV["TESTOPTS"]

    require "minitest/test_task"

    framework = %(require "minitest/autorun"; )

    @tester = Minitest::TestTask.create :test do |t|
      t.test_globs = [PATH]
    end

    assert_equal util_cmd_string(framework), util_exp_cmd
  end

  def test_make_test_cmd_for_minitest_prelude
    skip "Using TESTOPTS... skipping" if ENV["TESTOPTS"]

    require "minitest/test_task"

    prelude = %(require "other/file")
    framework = %(require "minitest/autorun"; )

    @tester = Minitest::TestTask.create :test do |t|
      t.test_prelude = prelude
      t.test_globs = [PATH]
    end

    assert_equal util_cmd_string(prelude, framework), util_exp_cmd
  end
end
