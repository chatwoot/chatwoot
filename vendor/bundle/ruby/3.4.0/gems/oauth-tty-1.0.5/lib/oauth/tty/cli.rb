# frozen_string_literal: true

module OAuth
  module TTY
    class CLI
      def self.puts_red(string)
        puts "\033[0;91m#{string}\033[0m"
      end

      ALIASES = {
        "h" => "help",
        "v" => "version",
        "q" => "query",
        "a" => "authorize",
        "s" => "sign"
      }.freeze

      def initialize(stdout, stdin, stderr, command, arguments)
        klass = get_command_class(parse_command(command))
        @command = klass.new(stdout, stdin, stderr, arguments)
        @help_command = Commands::HelpCommand.new(stdout, stdin, stderr, [])
      end

      def run
        @command.run
      end

      private

      def get_command_class(command)
        Object.const_get("OAuth::TTY::Commands::#{command.capitalize}Command")
      end

      def parse_command(command)
        case command = command.to_s.downcase
        when "--version", "-v"
          "version"
        when "--help", "-h", nil, ""
          "help"
        when *ALIASES.keys
          ALIASES[command]
        when *ALIASES.values
          command
        else
          OAuth::TTY::CLI.puts_red "Command '#{command}' not found"
          "help"
        end
      end
    end
  end
end
