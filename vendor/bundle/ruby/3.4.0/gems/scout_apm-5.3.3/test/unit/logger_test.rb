require 'test_helper'
require 'fileutils'

require 'scout_apm/logger'

class LoggerTest < Minitest::Test
  def setup
    @env_root = Pathname.new(File.expand_path(File.join(File.dirname(__FILE__), "..", "..")))
    FileUtils.mkdir_p(@env_root + "log")
  end

  def test_detect_stdout
    logger = ScoutApm::Logger.new("", { :log_file_path => "STDOUT"})
    assert logger.stdout?
    assert_equal STDOUT, logger.log_destination

    # and lowercase
    logger = ScoutApm::Logger.new("", { :log_file_path => "stdout"})
    assert logger.stdout?
    assert_equal STDOUT, logger.log_destination
  end

  def test_force_stdout
    logger = ScoutApm::Logger.new("", { :stdout => true })
    assert logger.stdout?
    assert_equal STDOUT, logger.log_destination
  end

  def test_pick_log_file_with_no_options
    logger = ScoutApm::Logger.new(@env_root, { })
    assert_equal (@env_root + "log" + "scout_apm.log").to_s, logger.log_destination
  end

  def test_pick_log_file_with_different_dir
    logger = ScoutApm::Logger.new(@env_root, { :log_file_path => "/tmp" })
    assert_equal "/tmp/scout_apm.log", logger.log_destination
  end

  def test_pick_log_file_invalid_dir
    logger = ScoutApm::Logger.new(@env_root, { :log_file_path => "/not_a_real_dir" })
    assert_equal STDOUT, logger.log_destination
  end

  def test_pick_log_dir_not_writable
    Dir.mktmpdir { |dir|
      # An unwritable dir
      FileUtils.chmod(0000, dir)
      logger = ScoutApm::Logger.new(@env_root, { :log_file_path => dir })
      assert_equal STDOUT, logger.log_destination

      # so it can be deleted
      FileUtils.chmod(0700, dir)
    }
  end

  def test_set_log_level
    logger = ScoutApm::Logger.new(@env_root, { :log_level => "debug" })
    assert_equal ::Logger::DEBUG, logger.log_level
  end

  def test_set_log_level_after
    logger = ScoutApm::Logger.new(@env_root, { :log_level => "debug" })
    logger.log_level = "info"
    assert_equal ::Logger::INFO, logger.log_level

    logger.log_level = ::Logger::ERROR
    assert_equal ::Logger::ERROR, logger.log_level
  end
end
