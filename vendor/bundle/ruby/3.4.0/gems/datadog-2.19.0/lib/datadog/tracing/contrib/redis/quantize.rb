# frozen_string_literal: true

require 'set'

module Datadog
  module Tracing
    module Contrib
      module Redis
        # Quantize contains Redis-specific resource quantization tools.
        module Quantize
          PLACEHOLDER = '?'
          TOO_LONG_MARK = '...'
          VALUE_MAX_LEN = 50
          CMD_MAX_LEN = 500

          AUTH_COMMANDS = %w[AUTH auth].freeze

          MULTI_VERB_COMMANDS = Set.new(
            %w[
              ACL
              CLIENT
              CLUSTER
              COMMAND
              CONFIG
              DEBUG
              LATENCY
              MEMORY
            ]
          ).freeze

          module_function

          def format_arg(arg)
            str = Core::Utils.utf8_encode(arg, binary: true, placeholder: PLACEHOLDER)
            Core::Utils.truncate(str, VALUE_MAX_LEN, TOO_LONG_MARK)
          rescue => e
            Datadog.logger.debug("non formattable Redis arg #{str}: #{e}")
            PLACEHOLDER
          end

          def format_command_args(command_args)
            command_args = resolve_command_args(command_args)
            return 'AUTH ?' if auth_command?(command_args)

            verb, *args = command_args.map { |x| format_arg(x) }
            Core::Utils.truncate("#{verb.upcase} #{args.join(' ')}", CMD_MAX_LEN, TOO_LONG_MARK)
          end

          def get_verb(command_args)
            return unless command_args.is_a?(Array)

            return get_verb(command_args.first) if command_args.first.is_a?(Array)

            verb = command_args.first.to_s.upcase
            return verb unless MULTI_VERB_COMMANDS.include?(verb) && command_args[1]

            "#{verb} #{command_args[1]}"
          end

          def auth_command?(command_args)
            return false unless command_args.is_a?(Array) && !command_args.empty?

            verb = command_args.first.to_s
            AUTH_COMMANDS.include?(verb)
          end

          # Unwraps command array when Redis is called with the following syntax:
          #   redis.call([:cmd, 'arg1', ...])
          def resolve_command_args(command_args)
            return command_args.first if command_args.is_a?(Array) && command_args.first.is_a?(Array)

            command_args
          end

          private_class_method :auth_command?, :resolve_command_args
        end
      end
    end
  end
end
