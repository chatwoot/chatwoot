# frozen_string_literal: true

require "forwardable"

require_relative "helpers/reflection"
require_relative "command_list"

module Byebug
  #
  # Subcommand additions.
  #
  module Subcommands
    def self.included(command)
      command.extend(ClassMethods)
    end

    extend Forwardable
    def_delegators "self.class", :subcommand_list

    #
    # Delegates to subcommands or prints help if no subcommand specified.
    #
    def execute
      subcmd_name = @match[1]
      return puts(help) unless subcmd_name

      subcmd = subcommand_list.match(subcmd_name)
      raise CommandNotFound.new(subcmd_name, self.class) unless subcmd

      subcmd.new(processor, arguments).execute
    end

    #
    # Class methods added to subcommands
    #
    module ClassMethods
      include Helpers::ReflectionHelper

      #
      # Default help text for a command with subcommands
      #
      def help
        super + subcommand_list.to_s
      end

      #
      # Command's subcommands.
      #
      def subcommand_list
        @subcommand_list ||= CommandList.new(commands)
      end
    end
  end
end
