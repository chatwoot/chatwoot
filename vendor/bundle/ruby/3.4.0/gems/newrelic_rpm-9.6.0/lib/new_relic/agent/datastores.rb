# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/datastores/metric_helper'

module NewRelic
  module Agent
    #
    # This module contains helper methods to facilitate instrumentation of
    # datastores not directly supported by the Ruby agent. It is intended to be
    # primarily used by authors of 3rd-party datastore instrumentation.
    #
    # @api public
    module Datastores
      # @!group Tracing query methods

      # Add Datastore tracing to a method. This properly generates the metrics
      # for New Relic's Datastore features. It does not capture the actual
      # query content into Transaction Traces. Use wrap if you want to provide
      # that functionality.
      #
      # @param [Class] klass the class to instrument
      #
      # @param [String, Symbol] method_name the name of instance method to
      #   instrument
      #
      # @param [String] product name of your datastore for use in metric naming, e.g. "Redis"
      #
      # @param [optional,String] operation the name of operation if different
      #   than the instrumented method name
      #
      # @api public
      #
      def self.trace(klass, method_name, product, operation = method_name)
        NewRelic::Agent.record_api_supportability_metric(:trace)

        klass.class_eval do
          method_name_without_newrelic = "#{method_name}_without_newrelic"

          if NewRelic::Helper.instance_methods_include?(klass, method_name) &&
              !NewRelic::Helper.instance_methods_include?(klass, method_name_without_newrelic)

            visibility = NewRelic::Helper.instance_method_visibility(klass, method_name)

            alias_method(method_name_without_newrelic, method_name)

            define_method(method_name) do |*args, &blk|
              segment = NewRelic::Agent::Tracer.start_datastore_segment(
                product: product,
                operation: operation
              )
              begin
                send(method_name_without_newrelic, *args, &blk)
              ensure
                ::NewRelic::Agent::Transaction::Segment.finish(segment)
              end
            end

            send(visibility, method_name)
            send(visibility, method_name_without_newrelic)
          end
        end
      end

      # Wrap a call to a datastore and record New Relic Datastore metrics. This
      # method can be used when a collection (i.e. table or model name) is
      # known at runtime to be included in the metric naming. It is intended
      # for situations that the simpler NewRelic::Agent::Datastores.trace can't
      # properly handle.
      #
      # To use this, wrap the datastore operation in the block passed to wrap.
      #
      #   NewRelic::Agent::Datastores.wrap("FauxDB", "find", "items") do
      #     FauxDB.find(query)
      #   end
      #
      # @param [String] product the datastore name for use in metric naming,
      #   e.g. "FauxDB"
      #
      # @param [String,Symbol] operation the name of operation (e.g. "select"),
      #   often named after the method that's being instrumented.
      #
      # @param [optional, String] collection the collection name for use in
      #   statement-level metrics (i.e. table or model name)
      #
      # @param [Proc,#call] callback proc or other callable to invoke after
      #   running the datastore block. Receives three arguments: result of the
      #   yield, the most specific (scoped) metric name, and elapsed time of the
      #   call. An example use is attaching SQL to Transaction Traces at the end
      #   of a wrapped datastore call.
      #
      #     callback = Proc.new do |result, metrics, elapsed|
      #       NewRelic::Agent::Datastores.notice_sql(query, metrics, elapsed)
      #     end
      #
      #     NewRelic::Agent::Datastores.wrap("FauxDB", "find", "items", callback) do
      #       FauxDB.find(query)
      #     end
      #
      # @note THERE ARE SECURITY CONCERNS WHEN CAPTURING QUERY TEXT!
      #   New Relic's Transaction Tracing and Slow SQL features will
      #   attempt to apply obfuscation to the passed queries, but it is possible
      #   for a query format to be unsupported and result in exposing user
      #   information embedded within captured queries.
      #
      # @api public
      #
      def self.wrap(product, operation, collection = nil, callback = nil)
        NewRelic::Agent.record_api_supportability_metric(:wrap)

        return yield unless operation

        segment = NewRelic::Agent::Tracer.start_datastore_segment(
          product: product,
          operation: operation,
          collection: collection
        )

        begin
          result = yield
        ensure
          begin
            if callback
              elapsed_time = Process.clock_gettime(Process::CLOCK_REALTIME) - segment.start_time
              callback.call(result, segment.name, elapsed_time)
            end
          ensure
            ::NewRelic::Agent::Transaction::Segment.finish(segment)
          end
        end
      end

      # @!group Capturing query / statement text

      # Wrapper for simplifying attaching SQL queries during a transaction.
      #
      # If you are recording non-SQL data, please use {notice_statement}
      # instead.
      #
      #   NewRelic::Agent::Datastores.notice_sql(query, metrics, elapsed)
      #
      # @param [String] query the SQL text to be captured. Note that depending
      #   on user settings, this string will be run through obfuscation, but
      #   some dialects of SQL (or non-SQL queries) are not guaranteed to be
      #   properly obfuscated by these routines!
      #
      # @param [String] scoped_metric The most specific metric relating to this
      #   query. Typically the result of
      #   NewRelic::Agent::Datastores::MetricHelper#metrics_for
      #
      # @param [Float] elapsed the elapsed time during query execution
      #
      # @note THERE ARE SECURITY CONCERNS WHEN CAPTURING QUERY TEXT!
      #   New Relic's Transaction Tracing and Slow SQL features will
      #   attempt to apply obfuscation to the passed queries, but it is possible
      #   for a query format to be unsupported and result in exposing user
      #   information embedded within captured queries.
      #
      # @api public
      #
      def self.notice_sql(query, scoped_metric, elapsed)
        NewRelic::Agent.record_api_supportability_metric(:notice_sql)

        if (txn = Tracer.current_transaction) && (segment = txn.current_segment) && segment.respond_to?(:notice_sql)
          segment.notice_sql(query)
        end
        nil
      end

      # Wrapper for simplifying attaching non-SQL data statements to a
      # transaction. For instance, Mongo or CQL queries, Memcached or Redis
      # keys would all be appropriate data to attach as statements.
      #
      # Data passed to this method is NOT obfuscated by New Relic, so please
      # ensure that user information is obfuscated if the agent setting
      # `transaction_tracer.record_sql` is set to `obfuscated`
      #
      #   NewRelic::Agent::Datastores.notice_statement("key", elapsed)
      #
      # @param [String] statement text of the statement to capture.
      #
      # @param [Float] elapsed the elapsed time during query execution
      #
      # @note THERE ARE SECURITY CONCERNS WHEN CAPTURING STATEMENTS!
      #   This method will properly ignore statements when the user has turned
      #   off capturing queries, but it is not able to obfuscate arbitrary data!
      #   To prevent exposing user information embedded in captured queries,
      #   please ensure all data passed to this method is safe to transmit to
      #   New Relic.
      #
      # @api public
      #
      def self.notice_statement(statement, elapsed)
        NewRelic::Agent.record_api_supportability_metric(:notice_statement)

        # Settings may change eventually, but for now we follow the same
        # capture rules as SQL for non-SQL statements.
        if (txn = Tracer.current_transaction) && (segment = txn.current_segment) && segment.respond_to?(:notice_nosql_statement)
          segment.notice_nosql_statement(statement)
        end
        nil
      end
    end
  end
end
