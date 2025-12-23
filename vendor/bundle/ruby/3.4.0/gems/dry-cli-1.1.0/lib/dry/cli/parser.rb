# frozen_string_literal: true

require "optparse"
require "dry/cli/program_name"

module Dry
  class CLI
    # Parse command line arguments and options
    #
    # @since 0.1.0
    # @api private
    module Parser
      # @since 0.1.0
      # @api private
      #
      def self.call(command, arguments, prog_name)
        original_arguments = arguments.dup
        parsed_options = {}

        OptionParser.new do |opts|
          command.options.each do |option|
            opts.on(*option.parser_options) do |value|
              parsed_options[option.name.to_sym] = value
            end
          end

          opts.on_tail("-h", "--help") do
            return Result.help
          end
        end.parse!(arguments)

        parsed_options = command.default_params.merge(parsed_options)
        parse_required_params(command, arguments, prog_name, parsed_options)
      rescue ::OptionParser::ParseError
        Result.failure("ERROR: \"#{prog_name}\" was called with arguments \"#{original_arguments.join(" ")}\"") # rubocop:disable Layout/LineLength
      end

      # @since 0.1.0
      # @api private
      #
      # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
      def self.parse_required_params(command, arguments, prog_name, parsed_options)
        parsed_params          = match_arguments(command.arguments, arguments)
        parsed_required_params = match_arguments(command.required_arguments, arguments)
        all_required_params_satisfied = command.required_arguments.all? { |param| !parsed_required_params[param.name].nil? } # rubocop:disable Layout/LineLength

        unused_arguments = arguments.drop(command.required_arguments.length)

        unless all_required_params_satisfied
          parsed_required_params_values = parsed_required_params.values.compact

          usage = "\nUsage: \"#{prog_name} #{command.required_arguments.map(&:description_name).join(" ")}" # rubocop:disable Layout/LineLength

          usage += " | #{prog_name} SUBCOMMAND" if command.subcommands.any?

          usage += '"'

          if parsed_required_params_values.empty?
            return Result.failure("ERROR: \"#{prog_name}\" was called with no arguments#{usage}")
          else
            return Result.failure("ERROR: \"#{prog_name}\" was called with arguments #{parsed_required_params_values}#{usage}") # rubocop:disable Layout/LineLength
          end
        end

        parsed_params.reject! { |_key, value| value.nil? }
        parsed_options = parsed_options.merge(parsed_params)
        parsed_options = parsed_options.merge(args: unused_arguments) if unused_arguments.any?
        Result.success(parsed_options)
      end
      # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity

      def self.match_arguments(command_arguments, arguments)
        result = {}

        command_arguments.each_with_index do |cmd_arg, index|
          if cmd_arg.array?
            result[cmd_arg.name] = arguments[index..]
            break
          else
            result[cmd_arg.name] = arguments.at(index)
          end
        end

        result
      end

      # @since 0.1.0
      # @api private
      class Result
        # @since 0.1.0
        # @api private
        def self.help
          new(help: true)
        end

        # @since 0.1.0
        # @api private
        def self.success(arguments = {})
          new(arguments: arguments)
        end

        # @since 0.1.0
        # @api private
        def self.failure(error = "Error: Invalid param provided")
          new(error: error)
        end

        # @since 0.1.0
        # @api private
        attr_reader :arguments

        # @since 0.1.0
        # @api private
        attr_reader :error

        # @since 0.1.0
        # @api private
        def initialize(arguments: {}, error: nil, help: false)
          @arguments = arguments
          @error     = error
          @help      = help
        end

        # @since 0.1.0
        # @api private
        def error?
          !error.nil?
        end

        # @since 0.1.0
        # @api private
        def help?
          @help
        end
      end
    end
  end
end
