# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

# These helpers should not have any gem dependencies except on newrelic_rpm
# itself, and should be usable from within any multiverse suite.

require 'json'
require 'net/http'
begin
  require 'net/http/status'
rescue LoadError
  # NOP -- Net::HTTP::STATUS_CODES was introduced in Ruby 2.5
end

class ArrayLogDevice
  def initialize(array = [])
    @array = array
  end
  attr_reader :array

  def write(message)
    @array << message
  end

  def close; end
end

def fake_guid(length = 16)
  NewRelic::Agent::GuidGenerator.generate_guid(length)
end

def assert_between(floor, ceiling, value, message = "expected #{floor} <= #{value} <= #{ceiling}")
  assert((floor <= value && value <= ceiling), message)
end

def assert_in_delta(expected, actual, delta)
  assert_between((expected - delta), (expected + delta), actual)
end

def harvest_error_traces!
  NewRelic::Agent.instance.error_collector.error_trace_aggregator.harvest!
end

def reset_error_traces!
  NewRelic::Agent.instance.error_collector.error_trace_aggregator.reset!
end

def assert_has_traced_error(error_class)
  errors = harvest_error_traces!

  refute_nil errors.find { |e| e.exception_class_name == error_class.name }, \
    "Didn't find error of class #{error_class}"
end

def last_traced_error
  harvest_error_traces!.last
end

def harvest_transaction_events!
  NewRelic::Agent.instance.transaction_event_aggregator.harvest!
end

def last_transaction_event
  harvest_transaction_events!.last.last
end

def harvest_span_events!
  NewRelic::Agent.instance.span_event_aggregator.harvest!
end

def last_span_event
  harvest_span_events!.last.last
end

def harvest_error_events!
  NewRelic::Agent.instance.error_collector.error_event_aggregator.harvest!
end

def last_error_event
  harvest_error_events!.last.last
end

unless defined? assert_includes
  def assert_includes(collection, member, msg = nil)
    msg = "Expected #{collection.inspect} to include #{member.inspect}"

    assert_includes collection, member, msg
  end
end

unless defined? assert_not_includes
  def assert_not_includes(collection, member, msg = nil)
    msg = "Expected #{collection.inspect} not to include #{member.inspect}"

    refute_includes collection, member, msg
  end
end

unless defined? assert_empty
  def assert_empty(collection, msg = nil)
    assert_empty collection, msg
  end
end

def assert_equal_unordered(left, right)
  assert_equal(left.length, right.length, "Lengths don't match. #{left.length} != #{right.length}")
  left.each { |element| assert_includes(right, element) }
end

def assert_log_contains(log, message)
  lines = log.array

  assert (lines.any? { |line| line.match(message) }),
    "Could not find message. Log contained: #{lines.join("\n")}"
end

def assert_audit_log_contains(audit_log_contents, needle)
  # Original request bodies dumped to the log have symbol keys, but once
  # they go through a dump/load, they're strings again, so we strip
  # double-quotes and colons from the log, and the strings we searching for.
  regex = /[:"]/
  needle = needle.gsub(regex, '')
  haystack = audit_log_contents.gsub(regex, '')

  assert_includes(haystack, needle, "Expected log to contain '#{needle}'")
end

# Because we don't generate a strictly machine-readable representation of
# request bodies for the audit log, the transformation into strings is
# effectively one-way. This, combined with the fact that Hash traversal order
# is arbitrary in Ruby 1.8.x means that it's difficult to directly assert that
# some object graph made it into the audit log (due to different possible
# orderings of the key/value pairs in Hashes that were embedded in the request
# body). So, this method traverses an object graph and only makes assertions
# about the terminal (non-Array-or-Hash) nodes therein.
def assert_audit_log_contains_object(audit_log_contents, o, format = :json)
  case o
  when Hash
    o.each do |k, v|
      assert_audit_log_contains_object(audit_log_contents, v, format)
      assert_audit_log_contains_object(audit_log_contents, k, format)
    end
  when Array

    o.each do |el|
      assert_audit_log_contains_object(audit_log_contents, el, format)
    end
  when NilClass

    assert_audit_log_contains(audit_log_contents, format == :json ? 'null' : 'nil')
  else
    assert_audit_log_contains(audit_log_contents, o.inspect)
  end
end

def compare_metrics(expected, actual)
  actual.delete_if { |a| a.include?('GC/Transaction/') }

  assert_equal(expected.to_a.sort, actual.to_a.sort, "extra: #{(actual - expected).to_a.inspect}; missing: #{(expected - actual).to_a.inspect}")
end

def metric_spec_from_specish(specish)
  spec = case specish
  when String then NewRelic::MetricSpec.new(specish)
  when Array then NewRelic::MetricSpec.new(*specish)
  end
  spec
end

def _normalize_metric_expectations(expectations)
  case expectations
  when Array
    hash = {}
    # Just assert that the metric is present, nothing about the attributes
    expectations.each { |k| hash[k] = {} }
    hash
  when String
    {expectations => {}}
  else
    expectations
  end
end

def dump_stats(stats)
  str = +"  Call count:           #{stats.call_count}\n"
  str << "  Total call time:      #{stats.total_call_time}\n"
  str << "  Total exclusive time: #{stats.total_exclusive_time}\n"
  str << "  Min call time:        #{stats.min_call_time}\n"
  str << "  Max call time:        #{stats.max_call_time}\n"
  str << "  Sum of squares:       #{stats.sum_of_squares}\n"
  str << "  Apdex S:              #{stats.apdex_s}\n"
  str << "  Apdex T:              #{stats.apdex_t}\n"
  str << "  Apdex F:              #{stats.apdex_f}\n"
  str
end

def assert_stats_has_values(stats, expected_spec, expected_attrs)
  expected_attrs.each do |attr, expected_value|
    actual_value = stats.send(attr)

    msg = "Expected #{attr} for #{expected_spec} to be #{'~' unless attr == :call_count}#{expected_value}, " \
          "got #{actual_value}.\nActual stats:\n#{dump_stats(stats)}"

    if attr == :call_count
      assert_stats_has_values_with_call_count(expected_value, actual_value, msg)
    else
      assert_in_delta(expected_value, actual_value, 0.0001, msg)
    end
  end
end

def assert_stats_has_values_with_call_count(expected_value, actual_value, msg)
  # >, <, >=, <= comparisons
  if expected_value.to_s =~ /([<>]=?)\s*(\d+)/
    operator = Regexp.last_match(1).to_sym
    count = Regexp.last_match(2).to_i

    assert_operator(actual_value, operator, count, msg)
  # == comparison
  else
    assert_equal(expected_value, actual_value, msg)
  end
end

def assert_metrics_recorded(expected)
  expected = _normalize_metric_expectations(expected)
  expected.each do |specish, expected_attrs|
    expected_spec = metric_spec_from_specish(specish)
    actual_stats = NewRelic::Agent.instance.stats_engine.to_h[expected_spec]
    if !actual_stats
      all_specs = NewRelic::Agent.instance.stats_engine.to_h.keys.sort
      matches = all_specs.select { |spec| spec.name == expected_spec.name }
      matches.map! { |m| "  #{m.inspect}" }

      msg = "Did not find stats for spec #{expected_spec.inspect}."
      msg += "\nDid find specs: [\n#{matches.join(",\n")}\n]" unless matches.empty?
      msg += "\nAll specs in there were: #{format_metric_spec_list(all_specs)}"

      assert(actual_stats, msg)
    end

    assert_stats_has_values(actual_stats, expected_spec, expected_attrs)
  end
end

# Use this to assert that *only* the given set of metrics has been recorded.
#
# If you want to scope the search for unexpected metrics to a particular
# namespace (e.g. metrics matching 'Controller/'), pass a Regex for the
# :filter option. Only metrics matching the regex will be searched when looking
# for unexpected metrics.
#
# If you want to *allow* unexpected metrics matching certain patterns, use
# the :ignore_filter option. This will allow you to specify a Regex that
# allowlists broad swathes of metric territory (e.g. 'Supportability/').
#
def assert_metrics_recorded_exclusive(expected, options = {})
  expected = _normalize_metric_expectations(expected)

  assert_metrics_recorded(expected)

  recorded_metrics = NewRelic::Agent.instance.stats_engine.to_h.keys

  if options[:filter]
    recorded_metrics = recorded_metrics.select { |m| m.name.match(options[:filter]) }
  end
  if options[:ignore_filter]
    recorded_metrics.reject! { |m| m.name.match(options[:ignore_filter]) }
  end

  expected_metrics = expected.keys.map { |s| metric_spec_from_specish(s) }

  unexpected_metrics = recorded_metrics - expected_metrics
  unexpected_metrics.reject! { |m| m.name.include?('GC/Transaction') }

  assert_equal(0, unexpected_metrics.size, "Found unexpected metrics: #{format_metric_spec_list(unexpected_metrics)}")
end

def assert_newrelic_metadata_present(metadata)
  assert metadata.key?('newrelic')
  refute_nil metadata['newrelic']
end

def assert_distributed_tracing_payload_created_for_transaction(transaction)
  assert transaction.distributed_tracer.instance_variable_get(:@distributed_trace_payload_created)
end

# The clear_metrics! method prevents metrics from "leaking" between tests by resetting
# the @stats_hash instance variable in the current instance of NewRelic::Agent::StatsEngine.

module NewRelic
  module Agent
    class StatsEngine
      def reset_for_test!
        @stats_hash = StatsHash.new
      end
    end
  end
end

def clear_metrics!
  NewRelic::Agent.instance.stats_engine.reset_for_test!
end

def assert_metrics_not_recorded(not_expected)
  not_expected = _normalize_metric_expectations(not_expected)
  found_but_not_expected = []
  not_expected.each do |specish, _|
    spec = metric_spec_from_specish(specish)
    if NewRelic::Agent.instance.stats_engine.to_h[spec]
      found_but_not_expected << spec
    end
  end

  assert_empty(found_but_not_expected, "Found unexpected metrics: #{format_metric_spec_list(found_but_not_expected)}")
end

alias :refute_metrics_recorded :assert_metrics_not_recorded

def assert_no_metrics_match(regex)
  matching_metrics = []
  NewRelic::Agent.instance.stats_engine.to_h.keys.map(&:to_s).each do |metric|
    matching_metrics << metric if metric.match(regex)
  end

  assert_empty(
    matching_metrics,
    "Found unexpected metrics:\n" + matching_metrics.map { |m| "  '#{m}'" }.join("\n") + "\n\n"
  )
end

alias :refute_metrics_match :assert_no_metrics_match

def format_metric_spec_list(specs)
  spec_strings = specs.map do |spec|
    "#{spec.name} (#{spec.scope.empty? ? '<unscoped>' : spec.scope})"
  end
  "[\n  #{spec_strings.join(",\n  ")}\n]"
end

def assert_truthy(expected, msg = nil)
  msg ||= "Expected #{expected.inspect} to be truthy"

  refute !expected, msg
end

def assert_falsy(expected, msg = nil)
  msg ||= "Expected #{expected.inspect} to be falsy"

  refute expected, msg
end

unless defined? assert_false
  def assert_false(expected)
    refute expected
  end
end

unless defined? refute
  alias refute assert_false
end

# Mock up a transaction for testing purposes, optionally specifying a name and
# transaction category. The given block will be executed within the context of the
# dummy transaction.
#
# Examples:
#
# With default name ('dummy') and category (:other):
#   in_transaction { ... }
#
# With an explicit transaction name and default category:
#   in_transaction('foobar') { ... }
#
# With default name and explicit category:
#   in_transaction(:category => :controller) { ... }
#
# With a transaction name plus category:
#   in_transaction('foobar', :category => :controller) { ... }
#
def in_transaction(*args, &blk)
  opts = args.last&.is_a?(Hash) ? args.pop : {}
  category = (opts&.delete(:category)) || :other

  # At least one test passes `:transaction_name => nil`, so handle it gently
  name = opts.key?(:transaction_name) ? opts.delete(:transaction_name) : args.first || 'dummy'

  state = NewRelic::Agent::Tracer.state
  txn = nil

  NewRelic::Agent::Tracer.in_transaction(name: name, category: category, options: opts) do
    txn = state.current_transaction
    yield(state.current_transaction)
  end

  txn
end

# Temporarily disables default transformer so tests with invalid inputs can be tried
def with_disabled_defaults_transformer(key)
  begin
    transformer = NewRelic::Agent::Configuration::DEFAULTS[key][:transform]
    NewRelic::Agent::Configuration::DEFAULTS[key][:transform] = nil
    yield
  ensure
    NewRelic::Agent::Configuration::DEFAULTS[key][:transform] = transformer
  end
end

# Convenience wrapper to stand up a transaction and provide a segment within
# that transaction to work with.  The same arguments as provided to in_transaction
# may be supplied.
def with_segment(*args, &blk)
  segment = nil
  txn = in_transaction(*args) do |t|
    segment = t.current_segment
    yield(segment, t)
  end
  [segment, txn]
end

# building error attributes on segments are deferred until it's time
# to publish/harvest them as spans, so for testing, we'll explicitly
# build 'em as appropriate so we can test 'em
def build_deferred_error_attributes(segment)
  return unless segment.noticed_error
  return if segment.noticed_error_attributes.frozen?

  segment.noticed_error.build_error_attributes
end

def capture_segment_with_error
  begin
    segment_with_error = nil
    with_segment do |segment|
      segment_with_error = segment
      raise 'oops!'
    end
  rescue Exception => exception
    assert segment_with_error, 'expected to have a segment_with_error'
    build_deferred_error_attributes(segment_with_error)
    return segment_with_error, exception
  end
end

def stub_transaction_guid(guid)
  NewRelic::Agent::Transaction.tl_current.instance_variable_set(:@guid, guid)
end

# Convenience wrapper around in_transaction that sets the category so that it
# looks like we are in a web transaction
def in_web_transaction(name = 'dummy')
  in_transaction(name, :category => :controller, :request => stub(:path => '/')) do |txn|
    yield(txn)
  end
end

def in_background_transaction(name = 'silly')
  in_transaction(name, :category => :task) do |txn|
    yield(txn)
  end
end

def refute_contains_request_params(attributes)
  attributes.keys.each do |key|
    refute_match(/^request\.parameters\./, key.to_s)
  end
end

def last_transaction_trace
  return unless last_sample = NewRelic::Agent.agent.transaction_sampler.last_sample

  NewRelic::Agent::Transaction::TraceBuilder.build_trace(last_sample)
end

def last_transaction_trace_request_params
  agent_attributes = attributes_for(last_transaction_trace, :agent)
  agent_attributes.inject({}) do |memo, (key, value)|
    memo[key] = value if key.to_s.start_with?('request.parameters.')
    memo
  end
end

def find_sql_trace(metric_name)
  NewRelic::Agent.agent.sql_sampler.sql_traces.values.detect do |trace|
    trace.database_metric_name == metric_name
  end
end

def last_sql_trace
  NewRelic::Agent.agent.sql_sampler.sql_traces.values.last
end

def find_last_transaction_node(transaction_sample = nil)
  if transaction_sample
    root_node = transaction_sample.root_node
  else
    root_node = last_transaction_trace.root_node
  end

  last_node = nil
  root_node.each_node { |s| last_node = s }

  return last_node
end

def find_node_with_name(transaction_sample, name)
  transaction_sample.root_node.each_node do |node|
    if node.metric_name == name
      return node
    end
  end

  nil
end

def find_node_with_name_matching(transaction_sample, regex)
  transaction_sample.root_node.each_node do |node|
    if node.metric_name.match(regex)
      return node
    end
  end

  nil
end

def find_all_nodes_with_name_matching(transaction_sample, regexes)
  regexes = [regexes].flatten
  matching_nodes = []

  transaction_sample.root_node.each_node do |node|
    regexes.each do |regex|
      if node.metric_name.match(regex)
        matching_nodes << node
      end
    end
  end

  matching_nodes
end

def with_config(config_hash, at_start = true)
  config = NewRelic::Agent::Configuration::DottedHash.new(config_hash, true)
  NewRelic::Agent.config.add_config_for_testing(config, at_start)
  NewRelic::Agent.instance.refresh_attribute_filter
  begin
    yield
  ensure
    NewRelic::Agent.config.remove_config(config)
    NewRelic::Agent.instance.refresh_attribute_filter
  end
end

def with_server_source(config_hash, at_start = true)
  with_config(config_hash, at_start) do
    NewRelic::Agent.config.notify_server_source_added
    yield
  end
end

def with_config_low_priority(config_hash)
  with_config(config_hash, false) do
    yield
  end
end

def with_transaction_renaming_rules(rule_specs)
  original_engine = NewRelic::Agent.agent.instance_variable_get(:@transaction_rules)
  begin
    new_engine = NewRelic::Agent::RulesEngine.create_transaction_rules('transaction_name_rules' => rule_specs)
    NewRelic::Agent.agent.instance_variable_set(:@transaction_rules, new_engine)
    yield
  ensure
    NewRelic::Agent.agent.instance_variable_set(:@transaction_rules, original_engine)
  end
end

# Need to guard against double-installing this patch because in 1.8.x the same
# file can be required multiple times under different non-canonicalized paths.
unless Time.respond_to?(:__original_now)
  Time.instance_eval do
    class << self
      attr_accessor :__frozen_now
      alias_method :__original_now, :now

      def now
        __frozen_now || __original_now
      end
    end
  end
end

def nr_freeze_time(now = Time.now)
  Time.__frozen_now = now
end

def nr_unfreeze_time
  Time.__frozen_now = nil
end

def advance_time(seconds)
  Time.__frozen_now = Time.now + seconds
end

unless Process.respond_to?(:__original_clock_gettime)
  Process.instance_eval do
    class << self
      attr_accessor :__frozen_clock_gettime
      alias_method :__original_clock_gettime, :clock_gettime

      def clock_gettime(clock_id, unit = :float_second)
        __frozen_clock_gettime || __original_clock_gettime(clock_id, unit)
      end
    end
  end
end

def advance_process_time(seconds, clock_id = Process::CLOCK_REALTIME)
  Process.__frozen_clock_gettime = Process.clock_gettime(clock_id) + seconds
end

def nr_freeze_process_time(now = Process.clock_gettime(Process::CLOCK_REALTIME))
  Process.__frozen_clock_gettime = now
end

def nr_unfreeze_process_time
  Process.__frozen_clock_gettime = nil
end

def with_constant_defined(constant_symbol, implementation = Module.new)
  const_path = constant_path(constant_symbol.to_s)

  if const_path
    # Constant is already defined, nothing to do
    return yield
  else
    const_path = constant_path(constant_symbol.to_s, :allow_partial => true)
    parent = const_path[-1]
    constant_symbol = constant_symbol.to_s.split('::').last.to_sym
  end

  begin
    parent.const_set(constant_symbol, implementation)
    yield
  ensure
    parent.send(:remove_const, constant_symbol)
  end
end

def constant_path(name, opts = {})
  allow_partial = opts[:allow_partial]
  path = [Object]
  parts = name.gsub(/^::/, '').split('::')
  parts.each do |part|
    if !path.last.constants.include?(part.to_sym)
      return allow_partial ? path : nil
    end

    path << path.last.const_get(part)
  end
  path
end

def get_parent(constant_name)
  parent_name = constant_name.gsub(/::[^:]*$/, '')
  const_path = constant_path(parent_name)
  const_path ? const_path[-1] : nil
end

def undefine_constant(constant_symbol)
  const_str = constant_symbol.to_s
  parent = get_parent(const_str)
  const_name = const_str.gsub(/.*::/, '')
  return yield unless parent&.constants&.include?(const_name.to_sym)

  removed_constant = parent.send(:remove_const, const_name)
  yield
ensure
  parent.const_set(const_name, removed_constant) if removed_constant
end

def with_debug_logging
  orig_logger = NewRelic::Agent.logger
  $stderr.puts '', '---', ''
  NewRelic::Agent.logger =
    NewRelic::Agent::AgentLogger.new('', Logger.new($stderr))

  with_config(:log_level => 'debug') do
    yield
  end
ensure
  NewRelic::Agent.logger = orig_logger
end

def create_agent_command(args = {})
  NewRelic::Agent::Commands::AgentCommand.new([-1, {'name' => 'command_name', 'arguments' => args}])
end

def wait_for_backtrace_service_poll(opts = {})
  defaults = {
    :timeout => 10.0,
    :service => NewRelic::Agent.agent.instance_variable_get(:@agent_command_router).backtrace_service,
    :iterations => 1
  }
  opts = defaults.merge(opts)
  deadline = Process.clock_gettime(Process::CLOCK_REALTIME) + opts[:timeout]

  service = opts[:service]
  worker_loop = service.worker_loop
  worker_loop.setup(0, service.method(:poll))

  until worker_loop.iterations > opts[:iterations]
    sleep(0.01)
    if Process.clock_gettime(Process::CLOCK_REALTIME) > deadline
      raise "Timed out waiting #{opts[:timeout]} s for backtrace service poll\n" +
        "Worker loop ran for #{opts[:service].worker_loop.iterations} iterations\n\n" +
        Thread.list.map { |t|
          "#{t.to_s}: newrelic_label: #{t[:newrelic_label].inspect}\n\n" +
            (t.backtrace || []).join("\n\t")
        }.join("\n\n")
    end
  end
end

def with_array_logger(level = :info)
  orig_logger = NewRelic::Agent.logger
  config = {:log_level => level}
  logdev = ArrayLogDevice.new
  override_logger = Logger.new(logdev)

  with_config(config) do
    NewRelic::Agent.logger = NewRelic::Agent::AgentLogger.new('', override_logger)
    yield
  end

  return logdev
ensure
  NewRelic::Agent.logger = orig_logger
end

# The EnvUpdater was introduced due to random fails in JRuby environment
# whereby attempting to set ENV[key] = some_value randomly failed.
# It is conjectured that this is thread related, but may also be
# a core bug in the JVM implementation of Ruby.  Root cause was not
# discovered, but it was found that a combination of retrying and using
# mutex lock around the update operation was the only consistently working
# solution as the error continued to surface without the mutex and
# retry alone wasn't enough, either.
#
# JRUBY: oraclejdk8 + jruby-9.2.6.0
#
# NOTE: Singleton pattern to ensure one mutex lock for all threads
class EnvUpdater
  MAX_RETRIES = 5

  def initialize
    @mutex = Mutex.new
  end

  # Will attempt the given block up to MAX_RETRIES before
  # surfacing the exception down the chain.
  def with_retry(retry_limit = MAX_RETRIES)
    retries ||= 0
    sleep(retries)
    yield
  rescue
    (retries += 1) < retry_limit ? retry : raise
  end

  # Locks and updates the ENV
  def safe_update(env)
    with_retry do
      @mutex.synchronize do
        env.each { |key, val| ENV[key] = val.to_s }
      end
    end
  end

  # Locks and restores the ENV
  def safe_restore(old_env)
    with_retry do
      @mutex.synchronize do
        old_env.each { |key, val| val ? ENV[key] = val : ENV.delete(key) }
      end
    end
  end

  # Singleton pattern implemented via @@instance
  def self.instance
    @@instance ||= EnvUpdater.new
  end

  def self.safe_update(env)
    instance.safe_update(env)
  end

  def self.safe_restore(old_env)
    instance.safe_restore(old_env)
  end

  # Effectively saves current ENV settings for given env's key/values,
  # runs given block, then restores ENV to original state before returning.
  def self.inject(env, &block)
    old_env = {}
    env.each { |key, val| old_env[key] = ENV[key] }
    begin
      safe_update(env)
      yield
    ensure
      safe_restore(old_env)
    end
  end

  # must call instance here to ensure only one @mutex for all threads.
  instance
end

# Changes ENV settings to given and runs given block and restores ENV
# to original values before returning.
def with_environment(env, &block)
  EnvUpdater.inject(env) { yield }
end

def with_argv(argv)
  old_argv = ARGV.dup
  ARGV.clear
  ARGV.concat(argv)

  begin
    yield
  ensure
    ARGV.clear
    ARGV.concat(old_argv)
  end
end

def with_ignore_error_filter(filter, &blk)
  original_filter = NewRelic::Agent.ignore_error_filter
  NewRelic::Agent.ignore_error_filter(&filter)

  yield
ensure
  NewRelic::Agent::ErrorCollector.ignore_error_filter = original_filter
end

def json_dump_and_encode(object)
  Base64.encode64(JSON.dump(object))
end

def get_last_analytics_event
  NewRelic::Agent.agent.transaction_event_aggregator.harvest![1].last
end

def swap_instance_method(target, method_name, new_method_implementation, &blk)
  old_method_implementation = target.instance_method(method_name)
  target.send(:define_method, method_name, new_method_implementation)
  yield
rescue NameError => e
  puts "Your target does not have the instance method #{method_name}"
  puts e.inspect
ensure
  target.send(:define_method, method_name, old_method_implementation)
end

def cross_agent_tests_dir
  File.expand_path(File.join(File.dirname(__FILE__), 'fixtures', 'cross_agent_tests'))
end

def load_cross_agent_test(name)
  test_file_path = File.join(cross_agent_tests_dir, "#{name}.json")
  data = File.read(test_file_path)
  data.gsub!('callCount', 'call_count')
  data = JSON.load(data)
  data.each { |testcase| testcase['testname'].tr!(' ', '_') if String === testcase['testname'] }
  data
end

def each_cross_agent_test(options)
  options = {:dir => nil, :pattern => '*'}.update(options)
  path = File.join([cross_agent_tests_dir, options[:dir], options[:pattern]].compact)
  Dir.glob(path).each { |file| yield(file) }
end

def assert_event_attributes(event, test_name, expected_attributes, non_expected_attributes)
  incorrect_attributes = []

  event_attrs = event[0]

  expected_attributes.each do |name, expected_value|
    actual_value = event_attrs[name]
    incorrect_attributes << name unless actual_value == expected_value
  end

  msg = +"Found missing or incorrect attribute values in #{test_name}:\n"

  incorrect_attributes.each do |name|
    msg << "  #{name}: expected = #{expected_attributes[name].inspect}, actual = #{event_attrs[name].inspect}\n"
  end
  msg << "\n"

  msg << "All event values:\n"
  event_attrs.each do |name, actual_value|
    msg << "  #{name}: #{actual_value.inspect}\n"
  end

  assert_empty(incorrect_attributes, msg)

  non_expected_attributes.each do |name|
    refute event_attrs[name], "Found value '#{event_attrs[name]}' for attribute '#{name}', but expected nothing in #{test_name}"
  end
end

def attributes_for(sample, type)
  sample.attributes.instance_variable_get("@#{type}_attributes")
end

def uncache_trusted_account_key
  NewRelic::Agent::Transaction::TraceContext::AccountHelpers.instance_variable_set(:@trace_state_entry_key, nil)
end

def reset_buffers_and_caches
  NewRelic::Agent.drop_buffered_data
  uncache_trusted_account_key
end

def message_for_status_code(code)
  # Net::HTTP::STATUS_CODES was introduced in Ruby 2.5
  if defined?(Net::HTTP::STATUS_CODES)
    return Net::HTTP::STATUS_CODES[code]
  end

  case code
  when 200 then 'OK'
  when 404 then 'Not Found'
  when 403 then 'Forbidden'
  else 'Unknown'
  end
end

# wraps the given headers in a Net::HTTPResponse which has accompanying
# http status code associated with it.
# a "status_code" may be passed in the headers to alter the HTTP Status Code
# that is wrapped in the response.
def mock_http_response(headers, wrap_it = true)
  status_code = (headers.delete('status_code') || 200).to_i
  net_http_resp = Net::HTTPResponse.new(1.0, status_code, message_for_status_code(status_code))
  headers.each do |key, value|
    net_http_resp.add_field(key.to_s, value)
  end
  return net_http_resp unless wrap_it

  NewRelic::Agent::HTTPClients::NetHTTPResponse.new(net_http_resp)
end

# +expected+ can be a string or regular expression
def assert_match_or_equal(expected, value)
  if expected.is_a?(Regexp)
    assert_match expected, value
  else
    assert_equal expected, value
  end
end

# selects the last segment with a noticed_error and checks
# the expectations against it.
def assert_segment_noticed_error(txn, segment_name, error_classes, error_message)
  error_segment = txn.segments.reverse.detect { |s| s.noticed_error }

  assert error_segment, 'Expected at least one segment with a noticed_error'

  assert_match_or_equal segment_name, error_segment.name

  noticed_error = error_segment.noticed_error

  assert_match_or_equal error_classes, noticed_error.exception_class_name
  assert_match_or_equal error_message, noticed_error.message
end

def assert_transaction_noticed_error(txn, error_classes)
  refute_empty txn.exceptions, 'Expected transaction to notice the error'
  assert_match_or_equal error_classes, txn.exceptions.keys.first.class.name
end

def refute_transaction_noticed_error(txn, error_class)
  error_segment = txn.segments.reverse.detect { |s| s.noticed_error }

  assert error_segment, 'Expected at least one segment with a noticed_error'
  assert_empty txn.exceptions, 'Expected transaction to NOT notice any segment errors'
end

def refute_raises(*exp)
  msg = "#{exp.pop}.\n" if String === exp.last

  begin
    yield
  rescue MiniTest::Skip => e
    puts "SKIP REPORTS: #{e.inspect}"
    return e if exp.include?(MiniTest::Skip)

    raise e
  rescue Exception => e
    puts "EXCEPTION RAISED: #{e.inspect}\n#{e.backtrace}"
    exp = exp.first if exp.size == 1

    flunk(msg || "unexpected exception raised: #{e}")
  end
end

def assert_implements(instance, method, *args)
  fail_message = "expected #{instance.class}##{method} method to be implemented"
  refute_raises NotImplementedError, fail_message do
    instance.send(method, *args)
  end
end

def defer_testing_to_min_supported_rails(test_file, min_rails_version, supports_jruby = true)
  if defined?(Rails) &&
      defined?(Rails::VERSION::STRING) &&
      (Rails::VERSION::STRING.to_f >= min_rails_version) &&
      (supports_jruby || !NewRelic::LanguageSupport.jruby?)

    yield
  else
    puts "Skipping tests in #{File.basename(test_file)} because Rails >= #{min_rails_version} is unavailable" if ENV['VERBOSE_TEST_OUTPUT']
  end
end
