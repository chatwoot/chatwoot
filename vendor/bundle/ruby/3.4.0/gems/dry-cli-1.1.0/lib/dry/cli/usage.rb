# frozen_string_literal: true

require "dry/cli/program_name"

module Dry
  class CLI
    # Command(s) usage
    #
    # @since 0.1.0
    # @api private
    module Usage
      # @since 0.1.0
      # @api private
      SUBCOMMAND_BANNER = " [SUBCOMMAND]"
      ROOT_COMMAND_WITH_SUBCOMMANDS_BANNER = " [ARGUMENT|SUBCOMMAND]"

      # @since 0.1.0
      # @api private
      def self.call(result)
        header = "Commands:"
        max_length, commands = commands_and_arguments(result)

        commands.map do |banner, node|
          usage = description(node.command) if node.leaf?
          "#{justify(banner, max_length, usage)}#{usage}"
        end.unshift(header).join("\n")
      end

      # @since 0.1.0
      # @api private
      def self.commands_and_arguments(result)
        max_length = 0
        ret        = commands(result).each_with_object({}) do |(name, node), memo|
          args = if node.command && node.leaf? && node.children?
                   ROOT_COMMAND_WITH_SUBCOMMANDS_BANNER
                 elsif node.leaf?
                   arguments(node.command)
                 else
                   SUBCOMMAND_BANNER
                 end

          partial       = "  #{command_name(result, name)}#{args}"
          max_length    = partial.bytesize if max_length < partial.bytesize
          memo[partial] = node
        end

        [max_length, ret]
      end

      # @since 0.1.0
      # @api private
      def self.arguments(command)
        return unless CLI.command?(command)

        required_arguments = command.required_arguments
        optional_arguments = command.optional_arguments

        required = required_arguments.map { |arg| arg.name.upcase }.join(" ") if required_arguments.any? # rubocop:disable Layout/LineLength
        optional = optional_arguments.map { |arg| "[#{arg.name.upcase}]" }.join(" ") if optional_arguments.any? # rubocop:disable Layout/LineLength
        result = [required, optional].compact

        " #{result.join(" ")}" unless result.empty?
      end

      # @since 0.1.0
      # @api private
      def self.description(command)
        return unless CLI.command?(command)

        " # #{command.description}" unless command.description.nil?
      end

      # @since 0.1.0
      # @api private
      def self.justify(string, padding, usage)
        return string.chomp(" ") if usage.nil?

        string.ljust(padding + padding / 2)
      end

      # @since 0.1.0
      # @api private
      def self.commands(result)
        result.children.sort_by { |name, _| name }
      end

      # @since 0.1.0
      # @api private
      def self.command_name(result, name)
        ProgramName.call([result.names, name])
      end
    end
  end
end
