# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'socket'
require 'net/https'
require 'net/http'
require 'logger'
require 'zlib'
require 'stringio'
require 'new_relic/constants'
require 'new_relic/traced_thread'
require 'new_relic/coerce'
require 'new_relic/agent/autostart'
require 'new_relic/agent/harvester'
require 'new_relic/agent/hostname'
require 'new_relic/agent/new_relic_service'
require 'new_relic/agent/pipe_service'
require 'new_relic/agent/configuration/manager'
require 'new_relic/agent/database'
require 'new_relic/agent/instrumentation/resque/helper'
require 'new_relic/agent/commands/agent_command_router'
require 'new_relic/agent/event_listener'
require 'new_relic/agent/distributed_tracing'
require 'new_relic/agent/monitors'
require 'new_relic/agent/transaction_event_recorder'
require 'new_relic/agent/custom_event_aggregator'
require 'new_relic/agent/span_event_aggregator'
require 'new_relic/agent/log_event_aggregator'
require 'new_relic/agent/sampler_collection'
require 'new_relic/agent/javascript_instrumentor'
require 'new_relic/agent/vm/monotonic_gc_profiler'
require 'new_relic/agent/utilization_data'
require 'new_relic/environment_report'
require 'new_relic/agent/attribute_filter'
require 'new_relic/agent/adaptive_sampler'
require 'new_relic/agent/connect/request_builder'
require 'new_relic/agent/connect/response_handler'

require 'new_relic/agent/agent_helpers/connect'
require 'new_relic/agent/agent_helpers/harvest'
require 'new_relic/agent/agent_helpers/start_worker_thread'
require 'new_relic/agent/agent_helpers/startup'
require 'new_relic/agent/agent_helpers/special_startup'
require 'new_relic/agent/agent_helpers/shutdown'
require 'new_relic/agent/agent_helpers/transmit'

module NewRelic
  module Agent
    # The Agent is a singleton that is instantiated when the plugin is
    # activated.  It collects performance data from ruby applications
    # in realtime as the application runs, and periodically sends that
    # data to the NewRelic server.
    class Agent
      def self.config
        ::NewRelic::Agent.config
      end

      include NewRelic::Agent::AgentHelpers::Connect
      include NewRelic::Agent::AgentHelpers::Harvest
      include NewRelic::Agent::AgentHelpers::StartWorkerThread
      include NewRelic::Agent::AgentHelpers::SpecialStartup
      include NewRelic::Agent::AgentHelpers::Startup
      include NewRelic::Agent::AgentHelpers::Shutdown
      include NewRelic::Agent::AgentHelpers::Transmit

      def initialize
        init_basics
        init_components
        init_event_handlers
        setup_attribute_filter
      end

      private

      def init_basics
        @started = false
        @event_loop = nil
        @worker_thread = nil
        @connect_state = :pending
        @connect_attempts = 0
        @waited_on_connect = nil
        @connected_pid = nil
        @wait_on_connect_mutex = Mutex.new
        @after_fork_lock = Mutex.new
        @wait_on_connect_condition = ConditionVariable.new
      end

      def init_components
        @service = NewRelicService.new
        @events = EventListener.new
        @stats_engine = StatsEngine.new
        @transaction_sampler = TransactionSampler.new
        @sql_sampler = SqlSampler.new
        @transaction_rules = RulesEngine.new
        @monotonic_gc_profiler = VM::MonotonicGCProfiler.new
        @adaptive_sampler = AdaptiveSampler.new(Agent.config[:sampling_target],
          Agent.config[:sampling_target_period_in_seconds])
      end

      def init_event_handlers
        @agent_command_router = Commands::AgentCommandRouter.new(@events)
        @monitors = Monitors.new(@events)
        @error_collector = ErrorCollector.new(@events)
        @harvest_samplers = SamplerCollection.new(@events)
        @javascript_instrumentor = JavaScriptInstrumentor.new(@events)
        @harvester = Harvester.new(@events)
        @transaction_event_recorder = TransactionEventRecorder.new(@events)
        @custom_event_aggregator = CustomEventAggregator.new(@events)
        @span_event_aggregator = SpanEventAggregator.new(@events)
        @log_event_aggregator = LogEventAggregator.new(@events)
      end

      def setup_attribute_filter
        refresh_attribute_filter

        @events.subscribe(:initial_configuration_complete) do
          refresh_attribute_filter
        end
      end

      public

      def refresh_attribute_filter
        @attribute_filter = AttributeFilter.new(Agent.config)
      end

      # contains all the class-level methods for NewRelic::Agent::Agent
      module ClassMethods
        # Should only be called by NewRelic::Control - returns a
        # memoized singleton instance of the agent, creating one if needed
        def instance
          @instance ||= self.new
        end
      end

      # Holds all the methods defined on NewRelic::Agent::Agent
      # instances
      module InstanceMethods
        # the statistics engine that holds all the timeslice data
        attr_reader :stats_engine
        # the transaction sampler that handles recording transactions
        attr_reader :transaction_sampler
        attr_reader :sql_sampler
        # error collector is a simple collection of recorded errors
        attr_reader :error_collector
        # whether we should record raw, obfuscated, or no sql
        attr_reader :record_sql
        # builder for JS agent scripts to inject
        attr_reader :javascript_instrumentor
        # cross application tracing ids and encoding
        attr_reader :cross_process_id
        # service for communicating with collector
        attr_reader :service
        # Global events dispatcher. This will provides our primary mechanism
        # for agent-wide events, such as finishing configuration, error notification
        # and request before/after from Rack.
        attr_reader :events

        # listens and responds to events that need to process headers
        # for synthetics and distributed tracing
        attr_reader :monitors
        # Transaction and metric renaming rules as provided by the
        # collector on connect.  The former are applied during txns,
        # the latter during harvest.
        attr_accessor :transaction_rules
        # GC::Profiler.total_time is not monotonic so we wrap it.
        attr_reader :monotonic_gc_profiler
        attr_reader :custom_event_aggregator
        attr_reader :span_event_aggregator
        attr_reader :log_event_aggregator
        attr_reader :transaction_event_recorder
        attr_reader :attribute_filter
        attr_reader :adaptive_sampler

        def transaction_event_aggregator
          @transaction_event_recorder.transaction_event_aggregator
        end

        def synthetics_event_aggregator
          @transaction_event_recorder.synthetics_event_aggregator
        end

        def agent_id=(agent_id)
          @service.agent_id = agent_id
        end

        # This method should be called in a forked process after a fork.
        # It assumes the parent process initialized the agent, but does
        # not assume the agent started.
        #
        # The call is idempotent, but not reentrant.
        #
        # * It clears any metrics carried over from the parent process
        # * Restarts the sampler thread if necessary
        # * Initiates a new agent run and worker loop unless that was done
        #   in the parent process and +:force_reconnect+ is not true
        #
        # Options:
        # * <tt>:force_reconnect => true</tt> to force the spawned process to
        #   establish a new connection, such as when forking a long running process.
        #   The default is false--it will only connect to the server if the parent
        #   had not connected.
        # * <tt>:keep_retrying => false</tt> if we try to initiate a new
        #   connection, this tells me to only try it once so this method returns
        #   quickly if there is some kind of latency with the server.
        def after_fork(options = {})
          return unless needs_after_fork_work?

          ::NewRelic::Agent.logger.debug("Starting the worker thread in #{Process.pid} (parent #{Process.ppid}) after forking.")

          channel_id = options[:report_to_channel]
          install_pipe_service(channel_id) if channel_id

          # Clear out locks and stats left over from parent process
          reset_objects_with_locks
          drop_buffered_data

          setup_and_start_agent(options)
        end

        def needs_after_fork_work?
          needs_restart = false
          @after_fork_lock.synchronize do
            needs_restart = @harvester.needs_restart?
            @harvester.mark_started
          end

          return false if !needs_restart ||
            !Agent.config[:agent_enabled] ||
            !Agent.config[:monitor_mode] ||
            disconnected? ||
            !control.security_settings_valid?

          true
        end

        def install_pipe_service(channel_id)
          @service = PipeService.new(channel_id)
          if connected?
            @connected_pid = Process.pid
          else
            ::NewRelic::Agent.logger.debug("Child process #{Process.pid} not reporting to non-connected parent (process #{Process.ppid}).")
            @service.shutdown
            disconnect
          end
        end

        def revert_to_default_configuration
          Agent.config.remove_config_type(:manual)
          Agent.config.remove_config_type(:server)
        end

        def trap_signals_for_litespeed
          # if litespeed, then ignore all future SIGUSR1 - it's
          # litespeed trying to shut us down
          if Agent.config[:dispatcher] == :litespeed
            Signal.trap('SIGUSR1', 'IGNORE')
            Signal.trap('SIGTERM', 'IGNORE')
          end
        end

        # Sets a thread local variable as to whether we should or
        # should not record sql in the current thread. Returns the
        # previous value, if there is one
        def set_record_sql(should_record) # THREAD_LOCAL_ACCESS
          state = Tracer.state
          prev = state.record_sql
          state.record_sql = should_record
          prev.nil? || prev
        end

        # Push flag indicating whether we should be tracing in this
        # thread. This uses a stack which allows us to disable tracing
        # children of a transaction without affecting the tracing of
        # the whole transaction
        def push_trace_execution_flag(should_trace = false) # THREAD_LOCAL_ACCESS
          Tracer.state.push_traced(should_trace)
        end

        # Pop the current trace execution status.  Restore trace execution status
        # to what it was before we pushed the current flag.
        def pop_trace_execution_flag # THREAD_LOCAL_ACCESS
          Tracer.state.pop_traced
        end

        # Clear out the metric data, errors, and transaction traces, etc.
        def drop_buffered_data
          @stats_engine.reset!
          @error_collector.drop_buffered_data
          @transaction_sampler.reset!
          @transaction_event_recorder.drop_buffered_data
          @custom_event_aggregator.reset!
          @span_event_aggregator.reset!
          @log_event_aggregator.reset!
          @sql_sampler.reset!

          if Agent.config[:clear_transaction_state_after_fork]
            Tracer.clear_state
          end
        end

        # Clear out state for any objects that we know lock from our parents
        # This is necessary for cases where we're in a forked child and Ruby
        # might be holding locks for background thread that aren't there anymore.
        def reset_objects_with_locks
          @stats_engine = StatsEngine.new
        end

        def flush_pipe_data
          if connected? && @service.is_a?(PipeService)
            transmit_data_types
          end
        end

        private

        # A shorthand for NewRelic::Control.instance
        def control
          NewRelic::Control.instance
        end

        def container_for_endpoint(endpoint)
          case endpoint
          when :metric_data then @stats_engine
          when :transaction_sample_data then @transaction_sampler
          when :error_data then @error_collector.error_trace_aggregator
          when :error_event_data then @error_collector.error_event_aggregator
          when :analytic_event_data then transaction_event_aggregator
          when :custom_event_data then @custom_event_aggregator
          when :span_event_data then span_event_aggregator
          when :sql_trace_data then @sql_sampler
          when :log_event_data then @log_event_aggregator
          end
        end

        def merge_data_for_endpoint(endpoint, data)
          if data && !data.empty?
            container = container_for_endpoint(endpoint)
            if container.respond_to?(:has_metadata?) && container.has_metadata?
              container_for_endpoint(endpoint).merge!(data, false)
            else
              container_for_endpoint(endpoint).merge!(data)
            end
          end
        rescue => e
          NewRelic::Agent.logger.error("Error while merging #{endpoint} data from child: ", e)
        end

        public :merge_data_for_endpoint
      end

      extend ClassMethods
      include InstanceMethods
    end
  end
end
