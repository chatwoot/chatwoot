# frozen_string_literal: true

module Sentry
  # @api private
  class Redis
    OP_NAME = "db.redis"
    SPAN_ORIGIN = "auto.db.redis"
    LOGGER_NAME = :redis_logger

    def initialize(commands, host, port, db)
      @commands, @host, @port, @db = commands, host, port, db
    end

    def instrument
      return yield unless Sentry.initialized?

      Sentry.with_child_span(op: OP_NAME, start_timestamp: Sentry.utc_now.to_f, origin: SPAN_ORIGIN) do |span|
        yield.tap do
          record_breadcrumb

          if span
            span.set_description(commands_description)
            span.set_data(Span::DataConventions::DB_SYSTEM, "redis")
            span.set_data(Span::DataConventions::DB_NAME, db)
            span.set_data(Span::DataConventions::SERVER_ADDRESS, host)
            span.set_data(Span::DataConventions::SERVER_PORT, port)
          end
        end
      end
    end

    private

    attr_reader :commands, :host, :port, :db

    def record_breadcrumb
      return unless Sentry.initialized?
      return unless Sentry.configuration.breadcrumbs_logger.include?(LOGGER_NAME)

      Sentry.add_breadcrumb(
        Sentry::Breadcrumb.new(
          level: :info,
          category: OP_NAME,
          type: :info,
          data: {
            commands: parsed_commands,
            server: server_description
          }
        )
      )
    end

    def commands_description
      parsed_commands.map do |statement|
        statement.values.join(" ").strip
      end.join(", ")
    end

    def parsed_commands
      commands.map do |statement|
        command, key, *arguments = statement
        command_set = { command: command.to_s.upcase }
        command_set[:key] = key if Utils::EncodingHelper.valid_utf_8?(key)

        if Sentry.configuration.send_default_pii
          command_set[:arguments] = arguments
                                    .select { |a| Utils::EncodingHelper.valid_utf_8?(a) }
                                    .join(" ")
        end

        command_set
      end
    end

    def server_description
      "#{host}:#{port}/#{db}"
    end

    module OldClientPatch
      def logging(commands, &block)
        Sentry::Redis.new(commands, host, port, db).instrument { super }
      end
    end

    module GlobalRedisInstrumentation
      def call(command, redis_config)
        Sentry::Redis
          .new([command], redis_config.host, redis_config.port, redis_config.db)
          .instrument { super }
      end

      def call_pipelined(commands, redis_config)
        Sentry::Redis
          .new(commands, redis_config.host, redis_config.port, redis_config.db)
          .instrument { super }
      end
    end
  end
end

if defined?(::Redis::Client)
  if Gem::Version.new(::Redis::VERSION) < Gem::Version.new("5.0")
    Sentry.register_patch(:redis, Sentry::Redis::OldClientPatch, ::Redis::Client)
  elsif defined?(RedisClient)
    Sentry.register_patch(:redis) do
      RedisClient.register(Sentry::Redis::GlobalRedisInstrumentation)
    end
  end
end
