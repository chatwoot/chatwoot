# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# frozen_string_literal: true

require 'erb'
require 'http'
require 'json'
require 'yaml'
require 'zlib'
require 'logger'
require 'concurrent'
require 'forwardable'
require 'securerandom'
require 'ruby2_keywords'

require 'elastic_apm/version'
require 'elastic_apm/internal_error'
require 'elastic_apm/logging'

# Core
require 'elastic_apm/fields'
require 'elastic_apm/agent'
require 'elastic_apm/config'
require 'elastic_apm/context'
require 'elastic_apm/instrumenter'
require 'elastic_apm/util'

require 'elastic_apm/middleware'
require 'elastic_apm/graphql'

require 'elastic_apm/rails' if defined?(::Rails::Railtie)
require 'elastic_apm/sinatra' if defined?(::Sinatra)
require 'elastic_apm/grape' if defined?(::Grape)
require 'elastic_apm/grpc' if defined?(::GRPC)

# ElasticAPM
module ElasticAPM
  class << self
    ### Life cycle

    # Starts the ElasticAPM Agent
    #
    # @param config [Config] An instance of Config
    # @return [Agent] The resulting [Agent]
    def start(config = {})
      Agent.start config
    end

    # Stops the ElasticAPM Agent
    def stop
      Agent.stop
    end

    # Restarts the ElasticAPM Agent using the same config or a new
    # one, if it is provided.
    # Starts the agent if it is not running.
    # Stops and starts the agent if it is running.
    def restart(config = nil)
      config ||= agent&.config
      stop if running?
      start(config)
    end

    # @return [Boolean] Whether there's an [Agent] running
    def running?
      Agent.running?
    end

    # @return [Agent] Currently running [Agent] if any
    def agent
      Agent.instance
    end

    ### Metrics

    # Returns the currently active transaction (if any)
    #
    # @return [Transaction] or `nil`
    def current_transaction
      agent&.current_transaction
    end

    # Returns the currently active span (if any)
    #
    # @return [Span] or `nil`
    def current_span
      agent&.current_span
    end

    # Get a formatted string containing transaction, span, and trace ids.
    # If a block is provided, the ids are yielded.
    #
    # @yield [String|nil, String|nil, String|nil] The transaction, span,
    # and trace ids.
    # @return [String] Unless block given
    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def log_ids
      trace_id = (current_transaction || current_span)&.trace_id
      if block_given?
        return yield(current_transaction&.id, current_span&.id, trace_id)
      end

      ids = []
      ids << "transaction.id=#{current_transaction.id}" if current_transaction
      ids << "span.id=#{current_span.id}" if current_span
      ids << "trace.id=#{trace_id}" if trace_id
      ids.join(' ')
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    # Start a new transaction
    #
    # @param name [String] A description of the transaction, eg
    # `ExamplesController#index`
    # @param type [String] The kind of the transaction, eg `app.request.get` or
    # `db.mysql2.query`
    # @param context [Context] An optional [Context]
    # @param trace_context [TraceContext] An optional [TraceContext] object for
    #   Distributed Tracing.
    # @return [Transaction]
    def start_transaction(
      name = nil,
      type = nil,
      context: nil,
      trace_context: nil
    )
      agent&.start_transaction(
        name,
        type,
        context: context,
        trace_context: trace_context
      )
    end

    # Ends the current transaction with `result`
    #
    # @param result [String] The result of the transaction
    # @return [Transaction]
    def end_transaction(result = nil)
      agent&.end_transaction(result)
    end

    # Wrap a block in a Transaction, ending it after the block
    #
    # @param name [String] A description of the transaction, eg
    # `ExamplesController#index`
    # @param type [String] The kind of the transaction, eg `app.request.get` or
    # `db.mysql2.query`
    # @param context [Context] An optional [Context]
    # @param trace_context [TraceContext] An optional [TraceContext] object for
    #   Distributed Tracing.
    # @yield [Transaction]
    # @return result of block
    def with_transaction(
      name = nil,
      type = nil,
      context: nil,
      trace_context: nil
    )
      unless block_given?
        raise ArgumentError,
          'expected a block. Do you want `start_transaction\' instead?'
      end

      return yield(nil) unless agent

      begin
        transaction =
          start_transaction(
            name,
            type,
            context: context,
            trace_context: trace_context
          )
        result = yield transaction
        transaction&.outcome ||= Transaction::Outcome::SUCCESS
        result
      rescue
        transaction&.outcome ||= Transaction::Outcome::FAILURE
        raise
      ensure
        end_transaction
      end
    end

    # rubocop:disable Metrics/ParameterLists
    # Start a new span
    #
    # @param name [String] A description of the span, eq `SELECT FROM "users"`
    # @param type [String] The span type, eq `db`
    # @param subtype [String] The span subtype, eq `postgresql`
    # @param action [String] The span action type, eq `connect` or `query`
    # @param context [Span::Context] Context information about the span
    # @param include_stacktrace [Boolean] Whether or not to capture a stacktrace
    # @param trace_context [TraceContext] An optional [TraceContext] object for
    #   Distributed Tracing.
    # @param parent [Transaction,Span] The parent transaction or span.
    #   Relevant when the span is created in another thread.
    # @param sync [Boolean] Whether the span is created synchronously or not.
    # @return [Span]
    def start_span(
      name,
      type = nil,
      subtype: nil,
      action: nil,
      context: nil,
      include_stacktrace: true,
      trace_context: nil,
      parent: nil,
      sync: nil
    )
      agent&.start_span(
        name,
        type,
        subtype: subtype,
        action: action,
        context: context,
        trace_context: trace_context,
        parent: parent,
        sync: sync
      ).tap do |span|
        break unless span && include_stacktrace
        break unless agent.config.span_frames_min_duration?

        span.original_backtrace ||= caller
      end
    end
    # rubocop:enable Metrics/ParameterLists

    # Ends the current span
    #
    # @param span [Span] Optional span to be ended instead of the last span
    #   created, useful for asynchronous environments where multiple spans are created in parallel
    #
    # @return [Span]
    def end_span(span = nil)
      agent&.end_span(span)
    end

    # rubocop:disable Metrics/ParameterLists
    # Wrap a block in a Span, ending it after the block
    #
    # @param name [String] A description of the span, eq `SELECT FROM "users"`
    # @param type [String] The kind of span, eq `db`
    # @param subtype [String] The subtype of span eg. `postgresql`.
    # @param action [String] The action type of span eg. `connect` or `query`.
    # @param context [Span::Context] Context information about the span
    # @param include_stacktrace [Boolean] Whether or not to capture a stacktrace
    # @param trace_context [TraceContext] An optional [TraceContext] object for
    #   Distributed Tracing.
    # @param parent [Transaction,Span] The parent transaction or span.
    #   Relevant when the span is created in another thread.
    # @param sync [Boolean] Whether the span is created synchronously or not.
    # @yield [Span]
    # @return Result of block
    def with_span(
      name,
      type = nil,
      subtype: nil,
      action: nil,
      context: nil,
      include_stacktrace: true,
      trace_context: nil,
      parent: nil,
      sync: nil
    )
      unless block_given?
        raise ArgumentError,
          'expected a block. Do you want `start_span\' instead?'
      end

      return yield nil unless agent

      begin
        span =
          start_span(
            name,
            type,
            subtype: subtype,
            action: action,
            context: context,
            include_stacktrace: include_stacktrace,
            trace_context: trace_context,
            parent: parent,
            sync: sync
          )
        result = yield span
        span&.outcome ||= Span::Outcome::SUCCESS
        result
      rescue
        span&.outcome ||= Span::Outcome::FAILURE
        raise
      ensure
        end_span
      end
    end
    # rubocop:enable Metrics/ParameterLists

    # Build a [Context] from a Rack `env`. The context may include information
    # about the request, response, current user and more
    #
    # @param rack_env [Rack::Env] A Rack env
    # @return [Context] The built context
    def build_context(
      rack_env: nil,
      for_type: :transaction
    )
      agent&.build_context(rack_env: rack_env, for_type: for_type)
    end

    ### Errors

    # Report and exception to APM
    #
    # @param exception [Exception] The exception
    # @param context [Context] An optional [Context]
    # @param handled [Boolean] Whether the exception was rescued
    # @return [String] ID of the generated [Error]
    def report(exception, context: nil, handled: true)
      agent&.report(exception, context: context, handled: handled)
    end

    # Report a custom string error message to APM
    #
    # @param message [String] The message
    # @param context [Context] An optional [Context]
    # @return [String] ID of the generated [Error]
    def report_message(message, context: nil, **attrs)
      agent&.report_message(
        message,
        context: context,
        backtrace: caller,
        **attrs
      )
    end

    ### Context

    # Set a _label_ value for the current transaction
    #
    # @param key [String,Symbol] A key
    # @param value [Object] A value
    # @return [Object] The given value
    def set_label(key, value)
      case value
      when TrueClass,
           FalseClass,
           Numeric,
           NilClass,
           String
        agent&.set_label(key, value)
      else
        agent&.set_label(key, value.to_s)
      end
    end

    # Provide further context for the current transaction
    #
    # @param custom [Hash] A hash with custom information. Can be nested.
    # @return [Hash] The current custom context
    def set_custom_context(custom)
      agent&.set_custom_context(custom)
    end

    # Provide a user to the current transaction
    #
    # @param user [Object] An object representing a user
    # @return [Object] Given user
    def set_user(user)
      agent&.set_user(user)
    end

    # Set destination fields on the current span
    #
    # @param address [String] Destination address
    # @param address [String] Destination address
    # @param address [Hash] Destination service
    # @param address [Hash] Destination cloud
    def set_destination(address: nil, port: nil, service: nil, cloud: nil)
      agent&.set_destination(address: address, port: port, service: service, cloud: cloud)
    end

    # Provide a filter to transform payloads before sending them off
    #
    # @param key [Symbol] Unique filter key
    # @param callback [Object, Proc] A filter that responds to #call(payload)
    # @yield [Hash] A filter. Used if provided. Otherwise using `callback`
    # @return [Bool] true
    def add_filter(key, callback = nil, &block)
      if callback.nil? && !block
        raise ArgumentError, '#add_filter needs either `callback\' or a block'
      end

      agent&.add_filter(key, block || callback)
    end
  end
end
