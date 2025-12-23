require 'test_helper'
require 'scout_apm/slow_transaction'
require 'scout_apm/metric_meta'
require 'scout_apm/metric_stats'
require 'scout_apm/context'
require 'scout_apm/store'

require 'fileutils'
class LayawayTest < Minitest::Test
  def test_directory_uses_DATA_FILE_option
    FileUtils.mkdir_p '/tmp/scout_apm_test/data_file_option'
    config = make_fake_config("data_file" => "/tmp/scout_apm_test/data_file_option")
    context = ScoutApm::AgentContext.new().tap{|c| c.config = config }
    layaway = ScoutApm::Layaway.new(context)

    assert_equal Pathname.new("/tmp/scout_apm_test/data_file_option"), layaway.directory
  end

  def test_directory_looks_for_root_slash_tmp
    FileUtils.mkdir_p '/tmp/scout_apm_test/tmp'
    config = make_fake_config({})
    env = make_fake_environment(:root => "/tmp/scout_apm_test")
    context = ScoutApm::AgentContext.new().tap{|c| c.config = config; c.environment = env }

    assert_equal Pathname.new("/tmp/scout_apm_test/tmp"), ScoutApm::Layaway.new(context).directory
  end

  def test_layaway_file_limit_prevents_new_writes
    FileUtils.mkdir_p '/tmp/scout_apm_test/layaway_limit'
    config = make_fake_config("data_file" => "/tmp/scout_apm_test/layaway_limit")
    context = ScoutApm::AgentContext.new().tap{|c| c.config = config }
    layaway = ScoutApm::Layaway.new(context)
    layaway.delete_files_for(:all)

    context = ScoutApm::AgentContext.new
    current_time = Time.now.utc
    current_rp = ScoutApm::StoreReportingPeriod.new(current_time, context)
    stale_rp = ScoutApm::StoreReportingPeriod.new(current_time - current_time.sec - 120, context)

    # layaway.write_reporting_period returns nil on successful write
    # It should probably be changed to return true or the number of bytes written
    assert_nil layaway.write_reporting_period(stale_rp, 1)

    # layaway.write_reporting_period returns an explicit false class on failure
    assert layaway.write_reporting_period(current_rp, 1).is_a?(FalseClass)

    layaway.delete_files_for(:all)
  end

  def test_layaway_stale_regex_pattern
    data_dir = '/tmp/scout_apm_test/shared/scout_apm'
    FileUtils.mkdir_p data_dir
    # Clean out files
    FileUtils.safe_unlink(Dir.glob("#{data_dir}/scout_*_*.data"))

    config = make_fake_config({'data_file' => data_dir})
    env = make_fake_environment(:root => '/tmp/scout_apm_test')
    context = ScoutApm::AgentContext.new().tap{|c| c.config = config; c.environment = env }
    layaway = ScoutApm::Layaway.new(context)


    not_stale_time = Time.now
    not_stale_time_formatted = not_stale_time.strftime(ScoutApm::Layaway::TIME_FORMAT)

    stale_time = not_stale_time - (ScoutApm::Layaway::STALE_AGE + 120) # ScoutApm::Layaway::STALE_AGE is in seconds. Add another 2 minutes to STALE_AGE
    stale_time_formatted = stale_time.strftime(ScoutApm::Layaway::TIME_FORMAT)

    not_stale_file_names = [File.join(data_dir, "scout_#{not_stale_time_formatted}_1.data"),
                            File.join(data_dir, "scout_#{not_stale_time_formatted}_20.data")]
    stale_file_names = [File.join(data_dir, "scout_#{stale_time_formatted}_1.data"),
                        File.join(data_dir, "scout_#{stale_time_formatted}_20.data")]
    all_file_names = not_stale_file_names + stale_file_names

    (all_file_names).each do |filename|
      File.new(filename, 'w').close
    end

    assert_equal Pathname.new("/tmp/scout_apm_test/shared/scout_apm"), ScoutApm::Layaway.new(context).directory
    assert_equal all_file_names.sort, Dir.glob("#{data_dir}/*data").sort

    layaway.delete_stale_files(not_stale_time - ScoutApm::Layaway::STALE_AGE)
    assert_equal not_stale_file_names.sort, Dir.glob("#{data_dir}/*data").sort
  end
end
