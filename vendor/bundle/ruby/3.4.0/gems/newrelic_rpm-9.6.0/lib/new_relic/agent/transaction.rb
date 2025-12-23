# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/instrumentation/queue_time'
require 'new_relic/agent/transaction_metrics'
require 'new_relic/agent/method_tracer_helpers'
require 'new_relic/agent/attributes'
require 'new_relic/agent/transaction/request_attributes'
require 'new_relic/agent/transaction/tracing'
require 'new_relic/agent/transaction/distributed_tracer'
require 'new_relic/agent/transaction_time_aggregator'
require 'new_relic/agent/deprecator'
require 'new_relic/agent/guid_generator'

module NewRelic
  module Agent
    # This class represents a single transaction (usually mapping to one
    # web request or background job invocation) instrumented by the Ruby agent.
    #
    # @api public
    class Transaction
      include Tracing

      # for nested transactions
      NESTED_TRANSACTION_PREFIX = 'Nested/'
      CONTROLLER_PREFIX = 'Controller/'
      MIDDLEWARE_PREFIX = 'Middleware/Rack/'
      OTHER_TRANSACTION_PREFIX = 'OtherTransaction/'
      TASK_PREFIX = "#{OTHER_TRANSACTION_PREFIX}Background/"
      RAKE_PREFIX = "#{OTHER_TRANSACTION_PREFIX}Rake/"
      MESSAGE_PREFIX = "#{OTHER_TRANSACTION_PREFIX}Message/"
      RACK_PREFIX = "#{CONTROLLER_PREFIX}Rack/"
      RODA_PREFIX = "#{CONTROLLER_PREFIX}Roda/"
      SINATRA_PREFIX = "#{CONTROLLER_PREFIX}Sinatra/"
      GRAPE_PREFIX = "#{CONTROLLER_PREFIX}Grape/"
      ACTION_CABLE_PREFIX = "#{CONTROLLER_PREFIX}ActionCable/"

      WEB_TRANSACTION_CATEGORIES = %i[action_cable controller grape middleware rack roda sinatra web uri].freeze

      MIDDLEWARE_SUMMARY_METRICS = ['Middleware/all'].freeze
      WEB_SUMMARY_METRIC = 'HttpDispatcher'
      OTHER_SUMMARY_METRIC = "#{OTHER_TRANSACTION_PREFIX}all"
      QUEUE_TIME_METRIC = 'WebFrontend/QueueTime'

      APDEX_S = 'S'
      APDEX_T = 'T'
      APDEX_F = 'F'
      APDEX_ALL_METRIC = 'ApdexAll'
      APDEX_METRIC = 'Apdex'
      APDEX_OTHER_METRIC = 'ApdexOther'
      APDEX_TXN_METRIC_PREFIX = 'Apdex/'
      APDEX_OTHER_TXN_METRIC_PREFIX = 'ApdexOther/Transaction/'

      JRUBY_CPU_TIME_ERROR = 'Error calculating JRuby CPU Time'

      # A Time instance for the start time, never nil
      attr_accessor :start_time

      # A Time instance used for calculating the apdex score, which
      # might end up being @start, or it might be further upstream if
      # we can find a request header for the queue entry time
      attr_accessor :apdex_start

      attr_accessor :exceptions,
        :filtered_params,
        :jruby_cpu_start,
        :process_cpu_start,
        :http_response_code,
        :response_content_length,
        :response_content_type,
        :parent_span_id

      attr_reader :guid,
        :metrics,
        :logs,
        :gc_start_snapshot,
        :category,
        :attributes,
        :payload,
        :nesting_max_depth,
        :segments,
        :end_time,
        :duration

      attr_writer :sampled,
        :priority

      # Populated with the trace sample once this transaction is completed.
      attr_reader :transaction_trace

      # Fields for tracking synthetics requests
      attr_accessor :raw_synthetics_header, :synthetics_payload, :synthetics_info_payload, :raw_synthetics_info_header

      # Return the currently active transaction, or nil.
      def self.tl_current
        Tracer.current_transaction
      end

      def self.set_default_transaction_name(partial_name, category = nil) # THREAD_LOCAL_ACCESS
        txn = tl_current
        name = name_from_partial(partial_name, category || txn.category)
        txn.set_default_transaction_name(name, category)
      end

      def self.set_overriding_transaction_name(partial_name, category = nil) # THREAD_LOCAL_ACCESS
        txn = tl_current
        return unless txn

        name = name_from_partial(partial_name, category || txn.category)
        txn.set_overriding_transaction_name(name, category)
      end

      def self.name_from_partial(partial_name, category)
        namer = Instrumentation::ControllerInstrumentation::TransactionNamer
        "#{namer.prefix_for_category(self, category)}#{partial_name}"
      end

      def self.start_new_transaction(state, category, options)
        txn = Transaction.new(category, options)
        state.reset(txn)
        txn.start(options)
        txn
      end

      def self.nested_transaction_name(name)
        if name.start_with?(CONTROLLER_PREFIX, OTHER_TRANSACTION_PREFIX)
          "#{NESTED_TRANSACTION_PREFIX}#{name}"
        else
          name
        end
      end

      # discards the currently saved transaction information
      def self.abort_transaction!
        if txn = Tracer.current_transaction
          txn.abort_transaction!
        end
      end

      # See NewRelic::Agent.notice_error for options and commentary
      def self.notice_error(e, options = {})
        if txn = Tracer.current_transaction
          txn.notice_error(e, options)
        elsif NewRelic::Agent.instance
          NewRelic::Agent.instance.error_collector.notice_error(e, options)
        end
      end

      # Returns truthy if the current in-progress transaction is considered a
      # a web transaction (as opposed to, e.g., a background transaction).
      #
      # @api public
      #
      def self.recording_web_transaction? # THREAD_LOCAL_ACCESS
        NewRelic::Agent.record_api_supportability_metric(:recording_web_transaction?)

        txn = tl_current
        txn&.recording_web_transaction?
      end

      def self.apdex_bucket(duration, failed, apdex_t)
        case
        when failed
          :apdex_f
        when duration <= apdex_t
          :apdex_s
        when duration <= apdex_t * 4
          :apdex_t
        else
          :apdex_f
        end
      end

      def self.add_agent_attribute(key, value, default_destinations)
        if txn = tl_current
          txn.add_agent_attribute(key, value, default_destinations)
        else
          NewRelic::Agent.logger.debug("Attempted to add agent attribute: #{key} without transaction")
        end
      end

      def add_agent_attribute(key, value, default_destinations)
        @attributes.add_agent_attribute(key, value, default_destinations)
        # the following line needs else branch coverage
        current_segment.add_agent_attribute(key, value) if current_segment # rubocop:disable Style/SafeNavigation
      end

      def self.merge_untrusted_agent_attributes(attributes, prefix, default_destinations)
        if txn = tl_current
          txn.merge_untrusted_agent_attributes(attributes, prefix, default_destinations)
        else
          NewRelic::Agent.logger.debug('Attempted to merge untrusted attributes without transaction')
        end
      end

      def merge_untrusted_agent_attributes(attributes, prefix, default_destinations)
        @attributes.merge_untrusted_agent_attributes(attributes, prefix, default_destinations)
        current_segment&.merge_untrusted_agent_attributes(attributes, prefix, default_destinations)
      end

      @@java_classes_loaded = false

      if defined? JRuby
        begin
          require 'java'
          java_import('java.lang.management.ManagementFactory')
          java_import('com.sun.management.OperatingSystemMXBean')
          @@java_classes_loaded = true
        rescue
        end
      end

      def initialize(category, options) # rubocop:disable Metrics/AbcSize
        @nesting_max_depth = 0
        @current_segment_by_thread = {}
        @current_segment_lock = Mutex.new
        @segments = []

        self.default_name = options[:transaction_name]
        @overridden_name = nil
        @frozen_name = nil

        @category = category
        @start_time = Process.clock_gettime(Process::CLOCK_REALTIME)
        @end_time = nil
        @duration = nil

        @apdex_start = options[:apdex_start_time] || @start_time
        @jruby_cpu_start = jruby_cpu_time
        @process_cpu_start = process_cpu
        @gc_start_snapshot = NewRelic::Agent::StatsEngine::GCProfiler.take_snapshot
        @filtered_params = options[:filtered_params] || {}

        @exceptions = {}
        @metrics = TransactionMetrics.new
        @logs = PrioritySampledBuffer.new(NewRelic::Agent.instance.log_event_aggregator.capacity)
        @guid = NewRelic::Agent::GuidGenerator.generate_guid

        @ignore_this_transaction = false
        @ignore_apdex = options.fetch(:ignore_apdex, false)
        @ignore_enduser = options.fetch(:ignore_enduser, false)
        @ignore_trace = false

        @sampled = nil
        @priority = nil

        @starting_thread_id = Thread.current.object_id
        @starting_segment_key = current_segment_key

        @attributes = Attributes.new(NewRelic::Agent.instance.attribute_filter)

        merge_request_parameters(@filtered_params)

        if request = options[:request]
          @request_attributes = RequestAttributes.new(request)
        else
          @request_attributes = nil
        end
      end

      def state
        NewRelic::Agent::Tracer.state
      end

      def current_segment_key
        Tracer.current_segment_key
      end

      def parent_segment_key
        (::Fiber.current.nr_parent_key if ::Fiber.current.respond_to?(:nr_parent_key)) || (::Thread.current.nr_parent_key if ::Thread.current.respond_to?(:nr_parent_key))
      end

      def current_segment
        current_segment_by_thread[current_segment_key] ||
          current_segment_by_thread[parent_segment_key] ||
          current_segment_by_thread[@starting_segment_key]
      end

      def set_current_segment(new_segment)
        @current_segment_lock.synchronize { current_segment_by_thread[current_segment_key] = new_segment }
      end

      def remove_current_segment_by_thread_id(id)
        @current_segment_lock.synchronize { current_segment_by_thread.delete(id) }
      end

      def distributed_tracer
        @distributed_tracer ||= DistributedTracer.new(self)
      end

      def sampled?
        return false unless Agent.config[:'distributed_tracing.enabled']

        if @sampled.nil?
          @sampled = NewRelic::Agent.instance.adaptive_sampler.sampled?
        end
        @sampled
      end

      def trace_id
        @trace_id ||= NewRelic::Agent::GuidGenerator.generate_guid(32)
      end

      def trace_id=(value)
        @trace_id = value
      end

      def priority
        @priority ||= (sampled? ? rand + 1.0 : rand).round(NewRelic::PRIORITY_PRECISION)
      end

      def referer
        @request_attributes&.referer
      end

      def request_path
        @request_attributes&.request_path
      end

      def request_port
        @request_attributes&.port
      end

      # This transaction-local hash may be used as temporary storage by
      # instrumentation that needs to pass data from one instrumentation point
      # to another.
      #
      # For example, if both A and B are instrumented, and A calls B
      # but some piece of state needed by the instrumentation at B is only
      # available at A, the instrumentation at A may write into the hash, call
      # through, and then remove the key afterwards, allowing the
      # instrumentation at B to read the value in between.
      #
      # Keys should be symbols, and care should be taken to not generate key
      # names dynamically, and to ensure that keys are removed upon return from
      # the method that creates them.
      #
      def instrumentation_state
        @instrumentation_state ||= {}
      end

      def overridden_name=(name)
        @overridden_name = Helper.correctly_encoded(name)
      end

      def default_name=(name)
        @default_name = Helper.correctly_encoded(name)
      end

      def merge_request_parameters(params)
        merge_untrusted_agent_attributes(params, :'request.parameters', AttributeFilter::DST_NONE)
      end

      def set_default_transaction_name(name, category)
        return log_frozen_name(name) if name_frozen?

        if influences_transaction_name?(category)
          self.default_name = name
          @category = category if category
        end
      end

      def set_overriding_transaction_name(name, category)
        return log_frozen_name(name) if name_frozen?

        self.overridden_name = name
        @category = category if category
      end

      def log_frozen_name(name)
        NewRelic::Agent.logger.warn("Attempted to rename transaction to '#{name}' after transaction name was already frozen as '#{@frozen_name}'.")
        nil
      end

      def influences_transaction_name?(category)
        !category || nesting_max_depth == 1 || similar_category?(category)
      end

      def best_name
        @frozen_name ||
          @overridden_name ||
          @default_name ||
          NewRelic::Agent::UNKNOWN_METRIC
      end

      # For common interface with Trace
      alias_method :transaction_name, :best_name
      # End common interface

      def promoted_transaction_name(name)
        if name.start_with?(MIDDLEWARE_PREFIX)
          "#{CONTROLLER_PREFIX}#{name}"
        else
          name
        end
      end

      def freeze_name_and_execute_if_not_ignored
        if !name_frozen?
          name = promoted_transaction_name(best_name)
          name = NewRelic::Agent.instance.transaction_rules.rename(name)
          @name_frozen = true

          if name.nil?
            ignore!
            @frozen_name = best_name
          else
            @frozen_name = name
          end
        end

        if block_given? && !@ignore_this_transaction
          yield
        end
      end

      def name_frozen?
        @frozen_name ? true : false
      end

      def start(options = {})
        return if !state.is_execution_traced?

        sql_sampler.on_start_transaction(state, request_path)
        NewRelic::Agent.instance.events.notify(:start_transaction)
        NewRelic::Agent::TransactionTimeAggregator.transaction_start(start_time)

        ignore! if user_defined_rules_ignore?

        create_initial_segment(options)
        Segment.merge_untrusted_agent_attributes( \
          @filtered_params,
          :'request.parameters',
          AttributeFilter::DST_SPAN_EVENTS
        )
      end

      def initial_segment
        segments.first
      end

      def finished?
        initial_segment&.finished?
      end

      def create_initial_segment(options = {})
        segment = create_segment(@default_name, options)
        segment.record_scoped_metric = false
      end

      def create_segment(name, options = {})
        summary_metrics = nil

        if name.start_with?(MIDDLEWARE_PREFIX)
          summary_metrics = MIDDLEWARE_SUMMARY_METRICS
        end

        @nesting_max_depth += 1

        segment = Tracer.start_segment(
          name: name,
          unscoped_metrics: summary_metrics
        )

        # #code_information will glean the code info out of the options hash
        # if it exists or noop otherwise
        segment.code_information = options

        segment
      end

      def create_nested_segment(category, options)
        if options[:filtered_params] && !options[:filtered_params].empty?
          @filtered_params = options[:filtered_params]
          merge_request_parameters(options[:filtered_params])
        end

        @ignore_apdex = options[:ignore_apdex] if options.key?(:ignore_apdex)
        @ignore_enduser = options[:ignore_enduser] if options.key?(:ignore_enduser)

        nest_initial_segment if segments.length == 1
        nested_name = self.class.nested_transaction_name(options[:transaction_name])

        segment = create_segment(nested_name, options)
        set_default_transaction_name(options[:transaction_name], category)
        segment
      end

      def nest_initial_segment
        self.initial_segment.name = self.class.nested_transaction_name(initial_segment.name)
        initial_segment.record_scoped_metric = true
      end

      # Call this to ensure that the current transaction trace is not saved
      # To fully ignore all metrics and errors, use ignore! instead.
      def abort_transaction!
        @ignore_trace = true
      end

      def summary_metrics
        if @frozen_name.start_with?(CONTROLLER_PREFIX)
          [WEB_SUMMARY_METRIC]
        else
          background_summary_metrics
        end
      end

      def background_summary_metrics
        segments = @frozen_name.split('/')
        if segments.size > 2
          ["OtherTransaction/#{segments[1]}/all", OTHER_SUMMARY_METRIC]
        else
          []
        end
      end

      def needs_middleware_summary_metrics?(name)
        name.start_with?(MIDDLEWARE_PREFIX)
      end

      def finish
        return unless state.is_execution_traced? && initial_segment

        @end_time = Process.clock_gettime(Process::CLOCK_REALTIME)
        @duration = @end_time - @start_time
        freeze_name_and_execute_if_not_ignored

        if nesting_max_depth == 1
          initial_segment.name = @frozen_name
        end

        initial_segment.transaction_name = @frozen_name
        assign_segment_dt_attributes
        assign_agent_attributes
        initial_segment.finish

        NewRelic::Agent::TransactionTimeAggregator.transaction_stop(@end_time, @starting_thread_id)

        commit!(initial_segment.name) unless @ignore_this_transaction
      rescue => e
        NewRelic::Agent.logger.error('Exception during Transaction#finish', e)
        nil
      ensure
        state.reset
      end

      def user_defined_rules_ignore?
        return false unless request_path
        return false if (rules = NewRelic::Agent.config[:"rules.ignore_url_regexes"]).empty?

        rules.any? do |rule|
          request_path.match(rule)
        end
      end

      def commit!(outermost_node_name)
        generate_payload
        assign_intrinsics

        finalize_segments

        @transaction_trace = transaction_sampler.on_finishing_transaction(self)
        sql_sampler.on_finishing_transaction(state, @frozen_name)

        record_summary_metrics(outermost_node_name)
        record_total_time_metrics
        record_apdex unless ignore_apdex?
        record_queue_time
        distributed_tracer.record_metrics

        record_exceptions
        record_transaction_event
        record_log_events
        merge_metrics
        send_transaction_finished_event
      end

      def assign_segment_dt_attributes
        dt_payload = distributed_tracer.trace_state_payload || distributed_tracer.distributed_trace_payload
        parent_attributes = {}
        DistributedTraceAttributes.copy_parent_attributes(self, dt_payload, parent_attributes)
        parent_attributes.each { |k, v| initial_segment.add_agent_attribute(k, v) }
      end

      def assign_agent_attributes
        default_destinations = AttributeFilter::DST_TRANSACTION_TRACER |
          AttributeFilter::DST_TRANSACTION_EVENTS |
          AttributeFilter::DST_ERROR_COLLECTOR

        if http_response_code
          add_agent_attribute(:'http.statusCode', http_response_code, default_destinations)
        end

        if response_content_length
          add_agent_attribute(:'response.headers.contentLength', response_content_length.to_i, default_destinations)
        end

        if response_content_type
          add_agent_attribute(:'response.headers.contentType', response_content_type, default_destinations)
        end

        @request_attributes&.assign_agent_attributes(self)

        display_host = Agent.config[:'process_host.display_name']
        unless display_host == NewRelic::Agent::Hostname.get
          add_agent_attribute(:'host.displayName', display_host, default_destinations)
        end
      end

      def assign_intrinsics
        attributes.add_intrinsic_attribute(:priority, priority)

        if gc_time = calculate_gc_time
          attributes.add_intrinsic_attribute(:gc_time, gc_time)
        end

        if burn = cpu_burn
          attributes.add_intrinsic_attribute(:cpu_time, burn)
        end

        if is_synthetics_request?
          attributes.add_intrinsic_attribute(:synthetics_resource_id, synthetics_resource_id)
          attributes.add_intrinsic_attribute(:synthetics_job_id, synthetics_job_id)
          attributes.add_intrinsic_attribute(:synthetics_monitor_id, synthetics_monitor_id)
          attributes.add_intrinsic_attribute(:synthetics_type, synthetics_info('type'))
          attributes.add_intrinsic_attribute(:synthetics_initiator, synthetics_info('initiator'))

          synthetics_additional_attributes do |key, value|
            attributes.add_intrinsic_attribute(key, value)
          end
        end

        distributed_tracer.assign_intrinsics
      end

      def synthetics_additional_attributes(&block)
        synthetics_info('attributes')&.each do |k, v|
          new_key = "synthetics_#{NewRelic::LanguageSupport.snakeize(k.to_s)}".to_sym
          yield(new_key, v.to_s)
        end
      end

      def calculate_gc_time
        gc_stop_snapshot = NewRelic::Agent::StatsEngine::GCProfiler.take_snapshot
        NewRelic::Agent::StatsEngine::GCProfiler.record_delta(gc_start_snapshot, gc_stop_snapshot)
      end

      # This method returns transport_duration in seconds. Transport duration
      # is stored in milliseconds on the payload, but it's needed in seconds
      # for metrics and intrinsics.
      def calculate_transport_duration(distributed_trace_payload)
        return unless distributed_trace_payload

        duration = start_time - (distributed_trace_payload.timestamp / 1000.0)
        [duration, 0].max
      end

      # The summary metrics recorded by this method all end up with a duration
      # equal to the transaction itself, and an exclusive time of zero.
      def record_summary_metrics(outermost_node_name)
        metrics = summary_metrics
        metrics << @frozen_name unless @frozen_name == outermost_node_name
        @metrics.record_unscoped(metrics, duration, 0)
      end

      # This event is fired when the transaction is fully completed. The metric
      # values and sampler can't be successfully modified from this event.
      def send_transaction_finished_event
        agent.events.notify(:transaction_finished, payload)
      end

      def generate_payload
        @payload = {
          :name => @frozen_name,
          :bucket => recording_web_transaction? ? :request : :background,
          :start_timestamp => start_time,
          :duration => duration,
          :metrics => @metrics,
          :attributes => @attributes,
          :error => false,
          :priority => priority
        }

        distributed_tracer.append_payload(@payload)
        append_apdex_perf_zone(@payload)
        append_synthetics_to(@payload)
      end

      def include_guid?
        distributed_tracer.is_cross_app? || is_synthetics_request?
      end

      def is_synthetics_request?
        !synthetics_payload.nil? && !raw_synthetics_header.nil?
      end

      def synthetics_version
        info = synthetics_payload or return nil
        info[0]
      end

      def synthetics_account_id
        info = synthetics_payload or return nil
        info[1]
      end

      def synthetics_resource_id
        info = synthetics_payload or return nil
        info[2]
      end

      def synthetics_job_id
        info = synthetics_payload or return nil
        info[3]
      end

      def synthetics_monitor_id
        info = synthetics_payload or return nil
        info[4]
      end

      def synthetics_info(key)
        synthetics_info_payload[key] if synthetics_info_payload
      end

      def append_apdex_perf_zone(payload)
        if recording_web_transaction?
          bucket = apdex_bucket(duration, apdex_t)
        elsif background_apdex_t = transaction_specific_apdex_t
          bucket = apdex_bucket(duration, background_apdex_t)
        end

        return unless bucket

        bucket_str = case bucket
        when :apdex_s then APDEX_S
        when :apdex_t then APDEX_T
        when :apdex_f then APDEX_F
        end
        payload[:apdex_perf_zone] = bucket_str if bucket_str
      end

      def append_synthetics_to(payload)
        return unless is_synthetics_request?

        payload[:synthetics_resource_id] = synthetics_resource_id
        payload[:synthetics_job_id] = synthetics_job_id
        payload[:synthetics_monitor_id] = synthetics_monitor_id
        payload[:synthetics_type] = synthetics_info('type')
        payload[:synthetics_initiator] = synthetics_info('initiator')

        synthetics_additional_attributes do |key, value|
          payload[key] = value
        end
      end

      def merge_metrics
        NewRelic::Agent.instance.stats_engine.merge_transaction_metrics!(@metrics, best_name)
      end

      def record_exceptions
        error_recorded = false
        @exceptions.each do |exception, options|
          error_recorded = record_exception(exception, options, error_recorded)
        end
        payload&.[]=(:error, error_recorded)
      end

      def record_exception(exception, options, error_recorded)
        options[:uri] ||= request_path if request_path
        options[:port] = request_port if request_port
        options[:metric] = best_name
        options[:attributes] = @attributes

        span_id = options.delete(:span_id)
        !!agent.error_collector.notice_error(exception, options, span_id) || error_recorded
      end

      # Do not call this.  Invoke the class method instead.
      def notice_error(error, options = {}) # :nodoc:
        # Only the last error is kept
        if current_segment
          current_segment.notice_error(error, expected: options[:expected])
          options[:span_id] = current_segment.guid
        end

        if @exceptions[error]
          @exceptions[error].merge!(options)
        else
          @exceptions[error] = options
        end
      end

      def record_transaction_event
        agent.transaction_event_recorder.record(payload)
      end

      def record_log_events
        agent.log_event_aggregator.record_batch(self, @logs.to_a)
      end

      def queue_time
        @apdex_start ? @start_time - @apdex_start : 0
      end

      def record_queue_time
        value = queue_time
        if value > 0.0
          if value < MethodTracerHelpers::MAX_ALLOWED_METRIC_DURATION
            @metrics.record_unscoped(QUEUE_TIME_METRIC, value)
          else
            ::NewRelic::Agent.logger.log_once(:warn, :too_high_queue_time, "Not recording unreasonably large queue time of #{value} s")
          end
        end
      end

      def had_error_affecting_apdex?
        @exceptions.each do |exception, options|
          ignored = NewRelic::Agent.instance.error_collector.error_is_ignored?(exception)
          expected = options[:expected]

          return true unless ignored || expected
        end
        false
      end

      def apdex_bucket(duration, current_apdex_t)
        self.class.apdex_bucket(duration, had_error_affecting_apdex?, current_apdex_t)
      end

      def record_apdex
        return unless state.is_execution_traced?

        freeze_name_and_execute_if_not_ignored do
          if recording_web_transaction?
            record_apdex_metrics(APDEX_METRIC, APDEX_TXN_METRIC_PREFIX, apdex_t)
          else
            record_apdex_metrics(APDEX_OTHER_METRIC,
              APDEX_OTHER_TXN_METRIC_PREFIX,
              transaction_specific_apdex_t)
          end
        end
      end

      def record_apdex_metrics(rollup_metric, transaction_prefix, current_apdex_t)
        return unless current_apdex_t

        total_duration = end_time - apdex_start
        apdex_bucket_global = apdex_bucket(total_duration, current_apdex_t)
        apdex_bucket_txn = apdex_bucket(duration, current_apdex_t)

        @metrics.record_unscoped(rollup_metric, apdex_bucket_global, current_apdex_t)
        @metrics.record_unscoped(APDEX_ALL_METRIC, apdex_bucket_global, current_apdex_t)
        txn_apdex_metric = @frozen_name.sub(/^[^\/]+\//, transaction_prefix)
        @metrics.record_unscoped(txn_apdex_metric, apdex_bucket_txn, current_apdex_t)
      end

      def apdex_t
        transaction_specific_apdex_t || Agent.config[:apdex_t]
      end

      def transaction_specific_apdex_t
        key = :web_transactions_apdex
        Agent.config[key] && Agent.config[key][best_name]
      end

      def threshold
        source_class = Agent.config.source(:'transaction_tracer.transaction_threshold').class
        if source_class == Configuration::DefaultSource
          apdex_t * 4
        else
          Agent.config[:'transaction_tracer.transaction_threshold']
        end
      end

      def with_database_metric_name(model, method, product = nil)
        previous = self.instrumentation_state[:datastore_override]
        model_name = case model
                     when Class
                       model.name
                     when String
                       model
                     else
                       model.to_s
        end
        self.instrumentation_state[:datastore_override] = [method, model_name, product]
        yield
      ensure
        self.instrumentation_state[:datastore_override] = previous
      end

      def add_custom_attributes(p)
        attributes.merge_custom_attributes(p)
      end

      def add_log_event(event)
        logs.append(event: event)
      end

      def recording_web_transaction?
        web_category?(@category)
      end

      def web_category?(category)
        WEB_TRANSACTION_CATEGORIES.include?(category)
      end

      def similar_category?(category)
        web_category?(@category) == web_category?(category)
      end

      def cpu_burn
        normal_cpu_burn || jruby_cpu_burn
      end

      def normal_cpu_burn
        return unless @process_cpu_start

        process_cpu - @process_cpu_start
      end

      def jruby_cpu_burn
        return unless @jruby_cpu_start

        jruby_cpu_time - @jruby_cpu_start
      end

      def ignore!
        @ignore_this_transaction = true
      end

      def ignore?
        @ignore_this_transaction
      end

      def ignore_apdex!
        @ignore_apdex = true
      end

      def ignore_apdex?
        @ignore_apdex
      end

      def ignore_enduser!
        @ignore_enduser = true
      end

      def ignore_enduser?
        @ignore_enduser
      end

      def ignore_trace?
        @ignore_trace
      end

      private

      def process_cpu
        return nil if defined? JRuby

        p = Process.times
        p.stime + p.utime
      end

      def jruby_cpu_time
        return nil unless @@java_classes_loaded

        threadMBean = Java::JavaLangManagement::ManagementFactory.getThreadMXBean()

        return nil unless threadMBean.isCurrentThreadCpuTimeSupported

        java_utime = threadMBean.getCurrentThreadUserTime() # ns

        -1 == java_utime ? 0.0 : java_utime / 1e9
      rescue => e
        ::NewRelic::Agent.logger.log_once(:warn, :jruby_cpu_time, JRUBY_CPU_TIME_ERROR, e)
        ::NewRelic::Agent.logger.debug(JRUBY_CPU_TIME_ERROR, e)
        nil
      end

      def agent
        NewRelic::Agent.instance
      end

      def transaction_sampler
        agent.transaction_sampler
      end

      def sql_sampler
        agent.sql_sampler
      end
    end
  end
end
