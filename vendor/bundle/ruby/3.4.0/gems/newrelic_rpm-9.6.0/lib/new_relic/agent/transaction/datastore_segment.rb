# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/transaction/segment'
require 'new_relic/agent/datastores/metric_helper'
require 'new_relic/agent/database'
require 'new_relic/agent/hostname'

module NewRelic
  module Agent
    class Transaction
      class DatastoreSegment < Segment
        UNKNOWN = 'unknown'.freeze

        attr_reader :product, :operation, :collection, :sql_statement, :nosql_statement, :host, :port_path_or_id
        attr_accessor :database_name, :record_sql

        def initialize(product, operation, collection = nil, host = nil, port_path_or_id = nil, database_name = nil, start_time = nil)
          @product = product
          @operation = operation
          @collection = collection
          @sql_statement = nil
          @nosql_statement = nil
          @record_sql = true
          set_instance_info(host, port_path_or_id)
          @database_name = database_name&.to_s
          super(Datastores::MetricHelper.scoped_metric_for(product, operation, collection),
                nil,
                start_time)
        end

        def set_instance_info(host = nil, port_path_or_id = nil)
          port_path_or_id = port_path_or_id.to_s if port_path_or_id
          host_present = host && !host.empty?
          ppi_present = port_path_or_id && !port_path_or_id.empty?

          host = NewRelic::Agent::Hostname.get_external(host) if host_present

          case
          when host_present && ppi_present
            @host = host
            @port_path_or_id = port_path_or_id

          when host_present && !ppi_present
            @host = host
            @port_path_or_id = UNKNOWN

          when !host_present && ppi_present
            @host = UNKNOWN
            @port_path_or_id = port_path_or_id

          else
            @host = @port_path_or_id = nil
          end
        end

        def notice_sql(sql)
          _notice_sql(sql)
          nil
        end

        # @api private
        def _notice_sql(sql, config = nil, explainer = nil, binds = nil, name = nil)
          return unless record_sql?

          @sql_statement = Database::Statement.new(sql, config, explainer, binds, name, host, port_path_or_id, database_name)
        end

        # Method for simplifying attaching non-SQL data statements to a
        # transaction. For instance, Mongo or CQL queries, Memcached or Redis
        # keys would all be appropriate data to attach as statements.
        #
        # Data passed to this method is NOT obfuscated by New Relic, so please
        # ensure that user information is obfuscated if the agent setting
        # `transaction_tracer.record_sql` is set to `obfuscated`
        #
        # @param [String] nosql_statement text of the statement to capture.
        #
        # @note THERE ARE SECURITY CONCERNS WHEN CAPTURING STATEMENTS!
        #   This method will properly ignore statements when the user has turned
        #   off capturing queries, but it is not able to obfuscate arbitrary data!
        #   To prevent exposing user information embedded in captured queries,
        #   please ensure all data passed to this method is safe to transmit to
        #   New Relic.

        def notice_nosql_statement(nosql_statement)
          return unless record_sql?

          @nosql_statement = Database.truncate_query(nosql_statement)
          nil
        end

        def record_metrics
          @unscoped_metrics = Datastores::MetricHelper.unscoped_metrics_for(product, operation, collection, host, port_path_or_id)
          super
        end

        private

        def segment_complete
          notice_sql_statement if sql_statement
          notice_statement if nosql_statement
          add_instance_parameters
          add_database_name_parameter
          add_backtrace_parameter

          super
        end

        def add_instance_parameters
          params[:host] = host if host
          params[:port_path_or_id] = port_path_or_id if port_path_or_id
        end

        def add_database_name_parameter
          params[:database_name] = database_name if database_name
        end

        NEWLINE = "\n".freeze

        def add_backtrace_parameter
          return unless duration >= Agent.config[:'transaction_tracer.stack_trace_threshold']

          params[:backtrace] = caller.join(NEWLINE)
        end

        def notice_sql_statement
          params[:sql] = sql_statement
          NewRelic::Agent.instance.sql_sampler.notice_sql_statement(sql_statement.dup, name, duration)
        end

        def notice_statement
          params[:statement] = nosql_statement
        end

        def record_sql?
          transaction_state.is_sql_recorded? && @record_sql
        end

        def record_span_event
          # don't record a span event if the transaction is ignored
          return if transaction.ignore?

          aggregator = ::NewRelic::Agent.agent.span_event_aggregator
          priority = transaction.priority

          aggregator.record(priority: priority) do
            SpanEventPrimitive.for_datastore_segment(self)
          end
        end
      end
    end
  end
end
