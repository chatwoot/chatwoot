# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module Datastores
      module Redis
        BINARY_DATA_PLACEHOLDER = '<binary data>'

        MAXIMUM_COMMAND_LENGTH = 1000
        MAXIMUM_ARGUMENT_LENGTH = 64
        CHUNK_SIZE = (MAXIMUM_ARGUMENT_LENGTH - 5) / 2
        PREFIX_RANGE = (0...CHUNK_SIZE)
        SUFFIX_RANGE = (-CHUNK_SIZE..-1)

        OBFUSCATE_ARGS = ' ?'
        ELLIPSES = '...'
        NEWLINE = "\n"
        SPACE = ' '
        QUOTE = '"'
        ALL_BUT_FIRST = (1..-1)

        STRINGS_SUPPORT_ENCODING = SPACE.respond_to?(:encoding)

        def self.format_command(command_with_args)
          if Agent.config[:'transaction_tracer.record_redis_arguments']
            result = +''

            append_command_with_args(result, command_with_args)

            trim_result(result) if result.length >= MAXIMUM_COMMAND_LENGTH
            result.strip!
            result
          end
        end

        def self.format_pipeline_commands(commands_with_args)
          result = +''

          commands_with_args.each do |command|
            if result.length >= MAXIMUM_COMMAND_LENGTH
              trim_result(result)
              break
            end

            append_pipeline_command(result, command)
            result << NEWLINE
          end

          result.strip!
          result
        end

        def self.append_pipeline_command(result, command_with_args)
          if Agent.config[:'transaction_tracer.record_redis_arguments']
            append_command_with_args(result, command_with_args)
          else
            append_command_with_no_args(result, command_with_args)
          end

          result
        end

        def self.append_command_with_args(result, command_with_args)
          result << command_with_args.first.to_s

          if command_with_args.size > 1
            command_with_args[ALL_BUT_FIRST].each do |arg|
              ellipsize(result, arg)

              break if result.length >= MAXIMUM_COMMAND_LENGTH
            end
          end

          result
        end

        def self.append_command_with_no_args(result, command_with_args)
          result << command_with_args.first.to_s
          result << OBFUSCATE_ARGS if command_with_args.size > 1
          result
        end

        def self.is_supported_version?
          Gem::Version.new(::Redis::VERSION) >= Gem::Version.new('3.0.0')
        end

        def self.ellipsize(result, string)
          result << SPACE
          if !string.is_a?(String)
            result << string.to_s
          elsif STRINGS_SUPPORT_ENCODING && string.encoding == Encoding::ASCII_8BIT
            result << BINARY_DATA_PLACEHOLDER
          elsif string.length > MAXIMUM_ARGUMENT_LENGTH
            result << QUOTE
            result << string[PREFIX_RANGE]
            result << ELLIPSES
            result << string[SUFFIX_RANGE]
            result << QUOTE
          else
            result << QUOTE
            result << string
            result << QUOTE
          end
        end

        def self.safe_from_third_party_gem?
          if NewRelic::LanguageSupport.bundled_gem?('newrelic-redis')
            ::NewRelic::Agent.logger.info('Not installing New Relic supported Redis instrumentation because the third party newrelic-redis gem is present')
            false
          else
            true
          end
        end

        def self.trim_result(result)
          result.slice!((MAXIMUM_COMMAND_LENGTH - ELLIPSES.length)..-1)
          result.strip!
          result << ELLIPSES
        end
      end
    end
  end
end
