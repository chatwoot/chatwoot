require 'test_helper'
require 'scout_apm/utils/backtrace_parser'

class BacktraceParserTest < Minitest::Test

  ################################################################################
  # Helpers

  def root
    "/Users/scout/secret-next-big-thing/current"
  end

  def raw_backtrace(count=10)
    count.times.map {|i| "#{root}/app/controllers/best_#{i}_controller.rb"}
  end

  ################################################################################
  # Tests

  def test_maxes_at_APP_FRAMES
    result = ScoutApm::Utils::BacktraceParser.new(raw_backtrace, root).call

    assert_equal ScoutApm::Utils::BacktraceParser::APP_FRAMES, result.length
  end

  def test_picks_off_top_of_trace
    result = ScoutApm::Utils::BacktraceParser.new(raw_backtrace, root).call

    assert_equal false, (result[0] =~ %r|app/controllers/best_0_controller.rb|).nil?
    assert_equal false, (result[1] =~ %r|app/controllers/best_1_controller.rb|).nil?
    assert_equal false, (result[2] =~ %r|app/controllers/best_2_controller.rb|).nil?
  end

  def test_trims_off_root_dir
    result = ScoutApm::Utils::BacktraceParser.new(raw_backtrace, root).call

    result.each do |r|
      assert_equal true, (r =~ %r|#{root}|).nil?
    end
  end

  def test_calls_scm_relative_path
    ScoutApm::Utils::Scm.expects(:relative_scm_path).at_least_once
    assert ScoutApm::Utils::BacktraceParser.new(raw_backtrace, root).call
  end

  def test_works_on_shorter_backtraces
    result = ScoutApm::Utils::BacktraceParser.new(raw_backtrace(1), root).call

    assert_equal 1, result.length
  end

  def test_works_with_no_in_app_frames
    result = ScoutApm::Utils::BacktraceParser.new(raw_backtrace, "/Users/scout/different-secrets").call
    assert_equal 0, result.length
  end

  def test_excludes_vendor_paths
    raw_backtrace = [
      "#{root}/vendor/ruby/thing.rb",
      "#{root}/app/controllers/users_controller.rb",
      "#{root}/vendor/ruby/thing.rb",
      "#{root}/config/initializers/inject_something.rb",
    ]
    result = ScoutApm::Utils::BacktraceParser.new(raw_backtrace, root).call

    assert_equal 2, result.length
    assert_equal false, (result[0] =~ %r|app/controllers/users_controller.rb|).nil?
    assert_equal false, (result[1] =~ %r|config/initializers/inject_something.rb|).nil?
  end
end
