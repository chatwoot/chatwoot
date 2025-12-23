require "spring/version"

module Spring
  module Client
    class Help < Command
      attr_reader :spring_commands, :application_commands

      def self.description
        "Print available commands."
      end

      def self.call(args)
        require "spring/commands"
        super
      end

      def initialize(args, spring_commands = nil, application_commands = nil)
        super args

        @spring_commands      = spring_commands      || Spring::Client::COMMANDS.dup
        @application_commands = application_commands || Spring.commands.dup

        @spring_commands.delete_if { |k, v| k.start_with?("-") }

        @application_commands["rails"] = @spring_commands.delete("rails")
      end

      def call
        puts formatted_help
      end

      def formatted_help
        ["Version: #{env.version}\n",
         "Usage: spring COMMAND [ARGS]\n",
         *command_help("Spring itself", spring_commands),
         '',
         *command_help("your application", application_commands)].join("\n")
      end

      def command_help(subject, commands)
        ["Commands for #{subject}:\n",
        *commands.sort_by(&:first).map { |name, command| display(name, command) }.compact]
      end

      private

      def all_commands
        spring_commands.merge application_commands
      end

      def display(name, command)
        if command.description
          "  #{name.ljust(max_name_width)}  #{command.description}"
        end
      end

      def max_name_width
        @max_name_width ||= all_commands.keys.map(&:length).max
      end
    end
  end
end
