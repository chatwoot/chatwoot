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

require 'elastic_apm/error'

require 'elastic_apm/context_builder'
require 'elastic_apm/error_builder'
require 'elastic_apm/stacktrace_builder'

require 'elastic_apm/central_config'
require 'elastic_apm/transport/base'
require 'elastic_apm/metrics'

require 'elastic_apm/spies'

module ElasticAPM
  # @api private
  class Agent
    include Logging
    extend Forwardable

    LOCK = Mutex.new

    # life cycle

    def self.instance # rubocop:disable Style/TrivialAccessors
      @instance
    end

    def self.start(config)
      return @instance if @instance

      config = Config.new(config) unless config.is_a?(Config)

      LOCK.synchronize do
        return @instance if @instance

        unless config.enabled?
          config.logger.debug format(
            "%sAgent disabled with `enabled: false'",
            Logging::PREFIX
          )
          return
        end

        @instance = new(config).start
      end
    end

    def self.stop
      LOCK.synchronize do
        return unless @instance

        @instance.stop
        @instance = nil
      end
    end

    def self.running?
      !!@instance
    end

    def initialize(config)
      @stacktrace_builder = StacktraceBuilder.new(config)
      @context_builder = ContextBuilder.new(config)
      @error_builder = ErrorBuilder.new(self)

      @central_config = CentralConfig.new(config)
      @transport = Transport::Base.new(config)
      @metrics = Metrics.new(config) { |event| enqueue event }
      @instrumenter = Instrumenter.new(
        config,
        metrics: metrics,
        stacktrace_builder: stacktrace_builder
      ) { |event| enqueue event }
      @pid = Process.pid
    end

    attr_reader(
      :central_config,
      :config,
      :context_builder,
      :error_builder,
      :instrumenter,
      :metrics,
      :stacktrace_builder,
      :transport
    )

    def_delegator :@central_config, :config

    def start
      unless config.disable_start_message?
        config.logger.info format(
          '[%s] Starting agent, reporting to %s',
          VERSION, config.server_url
        )
      end

      central_config.start
      transport.start
      instrumenter.start
      metrics.start

      config.enabled_instrumentations.each do |lib|
        debug "Requiring spy: #{lib}"
        require "elastic_apm/spies/#{lib}"
      end

      self
    end

    def stop
      info 'Stopping agent'

      central_config.stop
      metrics.stop
      instrumenter.stop
      transport.stop

      self
    end

    at_exit do
      stop
    end

    # transport

    def enqueue(obj)
      transport.submit obj
    end

    # instrumentation

    def current_transaction
      instrumenter.current_transaction
    end

    def current_span
      instrumenter.current_span
    end

    def start_transaction(
      name = nil,
      type = nil,
      context: nil,
      trace_context: nil
    )
      return unless config.recording?
      detect_forking!

      instrumenter.start_transaction(
        name,
        type,
        config: config,
        context: context,
        trace_context: trace_context
      )
    end

    def end_transaction(result = nil)
      instrumenter.end_transaction(result)
    end

    # rubocop:disable Metrics/ParameterLists
    def start_span(
      name = nil,
      type = nil,
      subtype: nil,
      action: nil,
      backtrace: nil,
      context: nil,
      trace_context: nil,
      parent: nil,
      sync: nil
    )
      detect_forking!

      # We don't check config.recording? because the span
      # will not be created if there's no transaction.
      # We want to use the recording value from the config
      # that existed when start_transaction was called. ~estolfo
      instrumenter.start_span(
        name,
        type,
        subtype: subtype,
        action: action,
        backtrace: backtrace,
        context: context,
        trace_context: trace_context,
        parent: parent,
        sync: sync
      )
    end
    # rubocop:enable Metrics/ParameterLists

    def end_span(span = nil)
      instrumenter.end_span(span)
    end

    def set_label(key, value)
      instrumenter.set_label(key, value)
    end

    def set_custom_context(context)
      instrumenter.set_custom_context(context)
    end

    def set_user(user)
      instrumenter.set_user(user)
    end

    def set_destination(address: nil, port: nil, service: nil, cloud: nil)
      current_span&.set_destination(address: nil, port: nil, service: nil, cloud: nil)
    end

    def build_context(rack_env:, for_type:)
      @context_builder.build(rack_env: rack_env, for_type: for_type)
    end

    # errors

    def report(exception, context: nil, handled: true)
      return unless config.recording?
      detect_forking!
      return if config.filter_exception_types.include?(exception.class.to_s)

      error = @error_builder.build_exception(
        exception,
        context: context,
        handled: handled
      )
      enqueue error
      error.id
    end

    def report_message(message, context: nil, backtrace: nil, **attrs)
      return unless config.recording?
      detect_forking!

      error = @error_builder.build_log(
        message,
        context: context,
        backtrace: backtrace,
        **attrs
      )
      enqueue error
      error.id
    end

    # filters

    def add_filter(key, callback)
      transport.add_filter(key, callback)
    end

    # misc

    def inspect
      super.split.first + '>'
    end

    def detect_forking!
      return if @pid == Process.pid

      config.logger.debug(
        "Forked process detected, restarting threads in process [PID:#{Process.pid}]")

      central_config.handle_forking!
      transport.handle_forking!
      instrumenter.handle_forking!
      metrics.handle_forking!

      @pid = Process.pid
    end
  end
end
