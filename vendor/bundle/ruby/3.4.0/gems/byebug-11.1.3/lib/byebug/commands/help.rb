# frozen_string_literal: true

require_relative "../command"
require_relative "../errors"

module Byebug
  #
  # Ask for help from byebug's prompt.
  #
  class HelpCommand < Command
    self.allow_in_control = true
    self.allow_in_post_mortem = true

    def self.regexp
      /^\s* h(?:elp)? (?:\s+(\S+))? (?:\s+(\S+))? \s*$/x
    end

    def self.description
      <<-DESCRIPTION
        h[elp][ <cmd>[ <subcmd>]]

        #{short_description}

        help                -- prints a summary of all commands
        help <cmd>          -- prints help on command <cmd>
        help <cmd> <subcmd> -- prints help on <cmd>'s subcommand <subcmd>
      DESCRIPTION
    end

    def self.short_description
      "Helps you using byebug"
    end

    def execute
      return help_for_all unless @match[1]

      return help_for(@match[1], command) unless @match[2]

      help_for(@match[2], subcommand)
    end

    private

    def help_for_all
      puts(processor.command_list.to_s)
    end

    def help_for(input, cmd)
      raise CommandNotFound.new(input, command) unless cmd

      puts(cmd.help)
    end

    def command
      @command ||= processor.command_list.match(@match[1])
    end

    def subcommand
      return unless command

      @subcommand ||= command.subcommand_list.match(@match[2])
    end
  end
end
