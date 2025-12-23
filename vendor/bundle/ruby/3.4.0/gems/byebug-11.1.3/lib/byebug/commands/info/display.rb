# frozen_string_literal: true

module Byebug
  #
  # Reopens the +info+ command to define the +display+ subcommand
  #
  class InfoCommand < Command
    #
    # Information about display expressions
    #
    class DisplayCommand < Command
      self.allow_in_post_mortem = true

      def self.regexp
        /^\s* d(?:isplay)? \s*$/x
      end

      def self.description
        <<-DESCRIPTION
          inf[o] d[display]

          #{short_description}
        DESCRIPTION
      end

      def self.short_description
        "List of expressions to display when program stops"
      end

      def execute
        return puts("There are no auto-display expressions now.") unless Byebug.displays.find { |d| d[0] }

        puts "Auto-display expressions now in effect:"
        puts "Num Enb Expression"

        Byebug.displays.each_with_index do |d, i|
          interp = format(
            "%<number>3d: %<status>s  %<expression>s",
            number: i + 1,
            status: d[0] ? "y" : "n",
            expression: d[1]
          )

          puts(interp)
        end
      end
    end
  end
end
