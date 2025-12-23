# Load & Start simplecov before loading scout_apm
require 'simplecov'
SimpleCov.start

require 'minitest/autorun'
require 'minitest/unit'
require 'minitest/pride'
require 'mocha/minitest'
require 'pry'


require 'active_support/core_ext/string/inflections'

require 'scout_apm'

Kernel.module_eval do
  # Unset a constant without private access.
  def self.const_unset(const)
    self.instance_eval { remove_const(const) }
  end

  def silence_warnings(&block)
    warn_level = $VERBOSE
    $VERBOSE = nil
    result = block.call
    $VERBOSE = warn_level
    result
  end
end

# A test helper class to create a temporary "configuration" we can control entirely purposes
class FakeConfigOverlay
  def initialize(values)
    @values = values
  end

  def value(key)
    @values[key]
  end

  def has_key?(key)
    @values.has_key?(key)
  end

  def name
    "agent-test-config-overlay"
  end

  def any_keys_found?
    true
  end
end

class FakeEnvironment
  def initialize(values)
    @values = values
  end

  def method_missing(sym)
    if @values.has_key?(sym)
      @values[sym]
    else
      raise "#{sym} not found in FakeEnvironment"
    end
  end
end

# Helpers available to all tests
class Minitest::Test
  def setup
    Thread.current[:scout_request] = nil
    reopen_logger
    FileUtils.mkdir_p(DATA_FILE_DIR)
    ENV['SCOUT_DATA_FILE'] = DATA_FILE_PATH
  end

  def teardown
    ScoutApm::Agent.instance.stop_background_worker
    File.delete(DATA_FILE_PATH) if File.exist?(DATA_FILE_PATH)
  end

  def set_rack_env(env)
    ENV['RACK_ENV'] = "production"
    ScoutApm::Environment.instance.instance_variable_set("@env", nil)
  end

  def reopen_logger
    @log_contents = StringIO.new
    @logger = Logger.new(@log_contents)
    ScoutApm::Agent.instance.instance_variable_set("@logger", @logger)
  end

  def make_fake_environment(values)
    FakeEnvironment.new(values)
  end

  # XXX: Make it easy to override context here?
  def make_fake_config(values)
    ScoutApm::Config.new(agent_context, [FakeConfigOverlay.new(values), ScoutApm::Config::ConfigNull.new] )
  end

  def agent_context
    ScoutApm::Agent.instance.context
  end

  DATA_FILE_DIR = File.dirname(__FILE__) + '/tmp'
  DATA_FILE_PATH = "#{DATA_FILE_DIR}/scout_apm.db"
end

class FakeRecorder
  attr_reader :requests

  def initialize
    @requests = []
  end

  def start
    # nothing to do
    self
  end

  def stop
    # nothing to do
  end

  def record!(request)
    @requests << request
  end
end

module CustomAsserts
  def assert_false(thing)
    assert !thing
  end
end

class Minitest::Test
  include CustomAsserts
end
