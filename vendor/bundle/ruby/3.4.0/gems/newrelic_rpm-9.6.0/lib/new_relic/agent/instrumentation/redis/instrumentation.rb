# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'constants'

module NewRelic::Agent::Instrumentation
  module Redis
    INSTRUMENTATION_NAME = NewRelic::Agent.base_name(name)

    def connect_with_tracing
      with_tracing(Constants::CONNECT, database: db) { yield }
    end

    def call_with_tracing(command, &block)
      operation = command[0]
      statement = ::NewRelic::Agent::Datastores::Redis.format_command(command)

      with_tracing(operation, statement: statement, database: db) { yield }
    end

    # Used for Redis 4.x and 3.x
    def call_pipeline_with_tracing(pipeline)
      operation = pipeline.is_a?(::Redis::Pipeline::Multi) ? Constants::MULTI_OPERATION : Constants::PIPELINE_OPERATION
      statement = ::NewRelic::Agent::Datastores::Redis.format_pipeline_commands(pipeline.commands)

      with_tracing(operation, statement: statement, database: db) { yield }
    end

    # Used for Redis 5.x+
    def call_pipelined_with_tracing(pipeline)
      db = begin
        _nr_redis_client_config.db
      rescue StandardError => e
        NewRelic::Agent.logger.error("Failed to determine configured Redis db value: #{e.class} - #{e.message}")
        nil
      end

      operation = pipeline.flatten.include?('MULTI') ? Constants::MULTI_OPERATION : Constants::PIPELINE_OPERATION
      statement = ::NewRelic::Agent::Datastores::Redis.format_pipeline_commands(pipeline)

      with_tracing(operation, statement: statement, database: db) { yield }
    end

    private

    def with_tracing(operation, statement: nil, database: nil)
      NewRelic::Agent.record_instrumentation_invocation(INSTRUMENTATION_NAME)

      segment = NewRelic::Agent::Tracer.start_datastore_segment(
        product: Constants::PRODUCT_NAME,
        operation: operation,
        host: _nr_hostname,
        port_path_or_id: _nr_port_path_or_id,
        database_name: database
      )
      begin
        segment.notice_nosql_statement(statement) if statement
        NewRelic::Agent::Tracer.capture_segment_error(segment) { yield }
      ensure
        ::NewRelic::Agent::Transaction::Segment.finish(segment)
      end
    end

    def _nr_hostname
      _nr_redis_client_config.path ? Constants::LOCALHOST : _nr_redis_client_config.host
    rescue => e
      NewRelic::Agent.logger.debug("Failed to retrieve Redis host: #{e.class} - #{e.message}")
      Constants::UNKNOWN
    end

    def _nr_port_path_or_id
      _nr_redis_client_config.path || _nr_redis_client_config.port
    rescue => e
      NewRelic::Agent.logger.debug("Failed to retrieve Redis port_path_or_id: #{e.class} - #{e.message}")
      Constants::UNKNOWN
    end

    def _nr_redis_client_config
      @nr_config ||= begin
        # redis gem
        config = if defined?(::Redis::Client) && self.is_a?(::Redis::Client)
          self
        # redis-client gem v0.11+ (self is a RedisClient::Middlewares)
        elsif respond_to?(:client)
          # The following line needs else branch coverage
          client && client.config # rubocop:disable Style/SafeNavigation
        # redis-client gem <0.11 (self is a RedisClient::Middlewares)
        elsif defined?(::RedisClient)
          ::RedisClient.config if ::RedisClient.respond_to?(:config)
        end
        raise 'Unable to locate the underlying Redis client configuration.' unless config

        config
      end
    end
  end
end
