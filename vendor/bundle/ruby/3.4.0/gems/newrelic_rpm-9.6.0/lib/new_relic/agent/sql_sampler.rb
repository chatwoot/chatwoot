# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'zlib'
require 'base64'
require 'digest/md5'

module NewRelic
  module Agent
    # This class contains the logic of recording slow SQL traces, which may
    # represent multiple aggregated SQL queries.
    #
    # A slow SQL trace consists of a collection of SQL instrumented SQL queries
    # that all normalize to the same text. For example, the following two
    # queries would be aggregated together into a single slow SQL trace:
    #
    #   SELECT * FROM table WHERE id=42
    #   SELECT * FROM table WHERE id=1234
    #
    # Each slow SQL trace keeps track of the number of times the same normalized
    # query was seen, the min, max, and total time spent executing those
    # queries, and an example backtrace from one of the aggregated queries.
    #
    # @api public
    class SqlSampler
      attr_reader :disabled

      # this is for unit tests only
      attr_reader :sql_traces

      MAX_SAMPLES = 10

      def initialize
        @sql_traces = {}

        # This lock is used to synchronize access to @sql_traces
        # and related variables. It can become necessary on JRuby or
        # any 'honest-to-god'-multithreaded system
        @samples_lock = Mutex.new
      end

      def enabled?
        Agent.config[:'slow_sql.enabled'] &&
          Agent.config[:'transaction_tracer.enabled'] &&
          NewRelic::Agent::Database.should_record_sql?(:slow_sql)
      end

      def on_start_transaction(state, uri = nil)
        return unless enabled?

        state.sql_sampler_transaction_data = TransactionSqlData.new

        if state.current_transaction
          guid = state.current_transaction.guid
        end

        if Agent.config[:'slow_sql.enabled'] && state.sql_sampler_transaction_data
          state.sql_sampler_transaction_data.set_transaction_info(uri, guid)
        end
      end

      def tl_transaction_data # only used for testing
        Tracer.state.sql_sampler_transaction_data
      end

      # This is called when we are done with the transaction.
      def on_finishing_transaction(state, name)
        return unless enabled?

        data = state.sql_sampler_transaction_data
        return unless data

        data.set_transaction_name(name)
        if data.sql_data.size > 0
          @samples_lock.synchronize do
            ::NewRelic::Agent.logger.debug("Examining #{data.sql_data.size} slow transaction sql statement(s)")
            save_slow_sql(data)
          end
        end
      end

      # this should always be called under the @samples_lock
      def save_slow_sql(transaction_sql_data)
        path = transaction_sql_data.path
        uri = transaction_sql_data.uri

        transaction_sql_data.sql_data.each do |sql_item|
          normalized_sql = sql_item.normalize
          sql_trace = @sql_traces[normalized_sql]
          if sql_trace
            sql_trace.aggregate(sql_item, path, uri)
          else
            if has_room?
              sql_trace = SqlTrace.new(normalized_sql, sql_item, path, uri)
            elsif should_add_trace?(sql_item)
              remove_shortest_trace
              sql_trace = SqlTrace.new(normalized_sql, sql_item, path, uri)
            end

            if sql_trace
              @sql_traces[normalized_sql] = sql_trace
            end
          end
        end
      end

      # this should always be called under the @samples_lock
      def should_add_trace?(sql_item)
        @sql_traces.any? do |(_, existing_trace)|
          existing_trace.max_call_time < sql_item.duration
        end
      end

      # this should always be called under the @samples_lock
      def has_room?
        @sql_traces.size < MAX_SAMPLES
      end

      # this should always be called under the @samples_lock
      def remove_shortest_trace
        shortest_key, _ = @sql_traces.min_by { |(_, trace)| trace.max_call_time }
        @sql_traces.delete(shortest_key)
      end

      # Records an SQL query, potentially creating a new slow SQL trace, or
      # aggregating the query into an existing slow SQL trace.
      #
      # This method should be used only by gem authors wishing to extend
      # the Ruby agent to instrument new database interfaces - it should
      # generally not be called directly from application code.
      #
      # @param sql [String] the SQL query being recorded
      # @param metric_name [String] is the metric name under which this query will be recorded
      # @param config [Object] is the driver configuration for the connection
      # @param duration [Float] number of seconds the query took to execute
      # @param explainer [Proc] for internal use only - 3rd-party clients must
      #                         not pass this parameter.
      #
      # @api public
      # @deprecated Use {Datastores.notice_sql} instead.
      #
      def notice_sql(sql, metric_name, config, duration, state = nil, explainer = nil, binds = nil, name = nil) # THREAD_LOCAL_ACCESS sometimes
        state ||= Tracer.state
        data = state.sql_sampler_transaction_data
        return unless data

        if state.is_sql_recorded?
          if duration > Agent.config[:'slow_sql.explain_threshold']
            backtrace = caller.join("\n")
            statement = Database::Statement.new(sql, config, explainer, binds, name)
            data.sql_data << SlowSql.new(statement, metric_name, duration, backtrace)
          end
        end
      end

      PRIORITY = 'priority'.freeze

      def distributed_trace_attributes(state)
        transaction = state.current_transaction
        params = nil
        if transaction&.distributed_tracer&.distributed_trace_payload
          params = {}
          payload = transaction.distributed_tracer.distributed_trace_payload
          DistributedTraceAttributes.copy_from_transaction(transaction, payload, params)
          params[PRIORITY] = transaction.priority
        end
        params
      end

      def notice_sql_statement(statement, metric_name, duration)
        state ||= Tracer.state
        data = state.sql_sampler_transaction_data
        return unless data

        if state.is_sql_recorded?
          if duration > Agent.config[:'slow_sql.explain_threshold']
            backtrace = caller.join("\n")
            params = distributed_trace_attributes(state)
            data.sql_data << SlowSql.new(statement, metric_name, duration, backtrace, params)
          end
        end
      end

      def merge!(sql_traces)
        @samples_lock.synchronize do
          sql_traces.each do |trace|
            existing_trace = @sql_traces[trace.sql]
            if existing_trace
              existing_trace.aggregate_trace(trace)
            else
              @sql_traces[trace.sql] = trace
            end
          end
        end
      end

      def harvest!
        return NewRelic::EMPTY_ARRAY unless enabled?

        slowest = []
        @samples_lock.synchronize do
          slowest = @sql_traces.values
          @sql_traces = {}
        end
        slowest.each { |trace| trace.prepare_to_send }
        slowest
      end

      def reset!
        @samples_lock.synchronize do
          @sql_traces = {}
        end
      end
    end

    class TransactionSqlData
      attr_reader :path
      attr_reader :uri
      attr_reader :sql_data
      attr_reader :guid

      def initialize
        @sql_data = []
      end

      def set_transaction_info(uri, guid)
        @uri = uri
        @guid = guid
      end

      def set_transaction_name(name)
        @path = name
      end
    end

    class SlowSql
      attr_reader :statement
      attr_reader :metric_name
      attr_reader :duration
      attr_reader :backtrace

      def initialize(statement, metric_name, duration, backtrace = nil, params = nil)
        @statement = statement
        @metric_name = metric_name
        @duration = duration
        @backtrace = backtrace
        @params = params
      end

      def sql
        statement.sql
      end

      def base_params
        params = @params || {}

        if NewRelic::Agent.config[:'datastore_tracer.instance_reporting.enabled']
          params[:host] = statement.host if statement.host
          params[:port_path_or_id] = statement.port_path_or_id if statement.port_path_or_id
        end
        if NewRelic::Agent.config[:'datastore_tracer.database_name_reporting.enabled'] && statement.database_name
          params[:database_name] = statement.database_name
        end

        params
      end

      def obfuscate
        NewRelic::Agent::Database.obfuscate_sql(statement)
      end

      def normalize
        NewRelic::Agent::Database::Obfuscator.instance \
          .default_sql_obfuscator(statement).gsub(/\?\s*\,\s*/, '').gsub(/\s/, '')
      end

      def explain
        if statement.config && statement.explainer
          NewRelic::Agent::Database.explain_sql(statement)
        end
      end

      # We can't serialize the explainer, so clear it before we transmit
      def prepare_to_send
        statement.explainer = nil
      end
    end

    class SqlTrace < Stats
      attr_reader :path
      attr_reader :url
      attr_reader :sql_id
      attr_reader :sql
      attr_reader :database_metric_name
      attr_reader :params
      attr_reader :slow_sql

      def initialize(normalized_query, slow_sql, path, uri)
        super()
        @params = slow_sql.base_params
        @sql_id = consistent_hash(normalized_query)
        set_primary(slow_sql, path, uri)
        record_data_point(float(slow_sql.duration))
      end

      def set_primary(slow_sql, path, uri)
        @slow_sql = slow_sql
        @sql = slow_sql.sql
        @database_metric_name = slow_sql.metric_name
        @path = path
        @url = uri
        @params[:backtrace] = slow_sql.backtrace if slow_sql.backtrace
      end

      def aggregate(slow_sql, path, uri)
        if slow_sql.duration > max_call_time
          set_primary(slow_sql, path, uri)
        end

        record_data_point(float(slow_sql.duration))
      end

      def aggregate_trace(trace)
        aggregate(trace.slow_sql, trace.path, trace.url)
      end

      def prepare_to_send
        params[:explain_plan] = @slow_sql.explain if need_to_explain?
        @sql = @slow_sql.obfuscate if need_to_obfuscate?
        @slow_sql.prepare_to_send
      end

      def need_to_obfuscate?
        Agent.config[:'slow_sql.record_sql'].to_s == 'obfuscated'
      end

      def need_to_explain?
        Agent.config[:'slow_sql.explain_enabled']
      end

      include NewRelic::Coerce

      def to_collector_array(encoder)
        [string(@path),
          string(@url),
          int(@sql_id),
          string(@sql),
          string(@database_metric_name),
          int(@call_count),
          Helper.time_to_millis(@total_call_time),
          Helper.time_to_millis(@min_call_time),
          Helper.time_to_millis(@max_call_time),
          encoder.encode(@params)]
      end

      private

      # need to hash the same way in every process, to be able to aggregate slow SQL traces
      def consistent_hash(string)
        if NewRelic::Agent.config[:'slow_sql.use_longer_sql_id']
          Digest::SHA1.hexdigest(string).hex.modulo(2**63 - 1)
        else
          # from when sql_id needed to fit in an INT(11)
          Digest::SHA1.hexdigest(string).hex.modulo(2**31 - 1)
        end
      end
    end
  end
end
