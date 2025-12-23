# frozen_string_literal: true

module Byebug
  #
  # Reopens the +info+ command to define the +args+ subcommand
  #
  class InfoCommand < Command
    #
    # Information about arguments of the current method/block
    #
    class ProgramCommand < Command
      self.allow_in_post_mortem = true

      def self.regexp
        /^\s* p(?:rogram)? \s*$/x
      end

      def self.description
        <<-DESCRIPTION
          inf[o] p[rogram]

          #{short_description}
        DESCRIPTION
      end

      def self.short_description
        "Information about the current status of the debugged program."
      end

      def execute
        puts "Program stopped. "
        format_stop_reason context.stop_reason
      end

      private

      def format_stop_reason(stop_reason)
        case stop_reason
        when :step
          puts "It stopped after stepping, next'ing or initial start."
        when :breakpoint
          puts "It stopped at a breakpoint."
        when :catchpoint
          puts "It stopped at a catchpoint."
        end
      end
    end
  end
end
