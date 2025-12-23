# frozen_string_literal: true

require_relative '../patcher'
require_relative 'ext'
require_relative 'quantize'
require_relative 'tags'

module Datadog
  module Tracing
    module Contrib
      module Redis
        # Instrumentation for Redis 5+
        module TraceMiddleware
          # Instruments {RedisClient::ConnectionMixin#call}.
          def call(command, redis_config)
            config = resolve(redis_config)
            TraceMiddleware.call(redis_config, command, config[:service_name], config[:command_args]) { super }
          end

          # Instruments {RedisClient::ConnectionMixin#call_pipelined}.
          def call_pipelined(commands, redis_config)
            config = resolve(redis_config)
            TraceMiddleware.call_pipelined(redis_config, commands, config[:service_name], config[:command_args]) { super }
          end

          class << self
            def call(client, command, service_name, command_args)
              Tracing.trace(Redis::Ext::SPAN_COMMAND, type: Redis::Ext::TYPE, service: service_name) do |span|
                raw_command = get_command(command, true)
                span.resource = command_args ? raw_command : get_command(command, false)

                Contrib::Redis::Tags.set_common_tags(client, span, raw_command)

                yield
              end
            end

            def call_pipelined(client, commands, service_name, command_args)
              Tracing.trace(Redis::Ext::SPAN_COMMAND, type: Redis::Ext::TYPE, service: service_name) do |span|
                raw_command = get_pipeline_commands(commands, true)
                span.resource = command_args ? raw_command : get_pipeline_commands(commands, false)

                span.set_metric Contrib::Redis::Ext::METRIC_PIPELINE_LEN, commands.length

                Contrib::Redis::Tags.set_common_tags(client, span, raw_command)

                yield
              end
            end

            private

            # Quantizes a single Redis command
            def get_command(command, command_args)
              if command_args
                Contrib::Redis::Quantize.format_command_args(command)
              else
                Contrib::Redis::Quantize.get_verb(command)
              end
            end

            # Quantizes a multi-command Redis pipeline execution
            def get_pipeline_commands(commands, command_args)
              list = if command_args
                       commands.map { |c| Contrib::Redis::Quantize.format_command_args(c) }
                     else
                       commands.map { |c| Contrib::Redis::Quantize.get_verb(c) }
                     end

              list.empty? ? '(none)' : list.join("\n")
            end
          end

          private

          def resolve(redis_config)
            custom = redis_config.custom[:datadog] || {}

            Datadog.configuration.tracing[:redis, redis_config.server_url].to_h.merge(custom)
          end
        end
      end
    end
  end
end
