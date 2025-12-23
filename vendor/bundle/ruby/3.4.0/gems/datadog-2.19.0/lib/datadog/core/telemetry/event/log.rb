# frozen_string_literal: true

require_relative 'base'

module Datadog
  module Core
    module Telemetry
      module Event
        # Telemetry class for the 'logs' event.
        # Logs with the same content are deduplicated at flush time.
        class Log < Base
          LEVELS = {
            error: 'ERROR',
            warn: 'WARN',
          }.freeze

          LEVELS_STRING = LEVELS.values.freeze

          attr_reader :message, :level, :stack_trace, :count

          def type
            'logs'
          end

          # @param message [String] the log message
          # @param level [Symbol, String] the log level. Either :error, :warn, 'ERROR', or 'WARN'.
          # @param stack_trace [String, nil] the stack trace
          # @param count [Integer] the number of times the log was emitted. Used for deduplication.
          def initialize(message:, level:, stack_trace: nil, count: 1)
            super()
            @message = message
            @stack_trace = stack_trace

            if level.is_a?(String) && LEVELS_STRING.include?(level)
              # String level is used during object copy for deduplication
              @level = level
            elsif level.is_a?(Symbol)
              # Symbol level is used by the regular log emitter user
              @level = LEVELS.fetch(level) { |k| raise ArgumentError, "Invalid log level :#{k}" }
            else
              raise ArgumentError, "Invalid log level #{level}"
            end

            @count = count
          end

          def payload
            {
              logs: [
                {
                  message: @message,
                  level: @level,
                  stack_trace: @stack_trace,
                  count: @count,
                }.compact
              ]
            }
          end

          # override equality to allow for deduplication
          def ==(other)
            other.is_a?(Log) &&
              other.message == @message &&
              other.level == @level && other.stack_trace == @stack_trace && other.count == @count
          end

          alias_method :eql?, :==

          def hash
            [self.class, @message, @level, @stack_trace, @count].hash
          end
        end
      end
    end
  end
end
