# frozen_string_literal: true

require_relative "../../helpers/toggle"

module Byebug
  #
  # Reopens the +disable+ command to define the +breakpoints+ subcommand
  #
  class DisableCommand < Command
    #
    # Disables all or specific breakpoints
    #
    class BreakpointsCommand < Command
      include Helpers::ToggleHelper

      self.allow_in_post_mortem = true

      def self.regexp
        /^\s* b(?:reakpoints)? (?:\s+ (.+))? \s*$/x
      end

      def self.description
        <<-DESCRIPTION
          dis[able] b[reakpoints][ <id1> <id2> .. <idn>]

          #{short_description}

          Give breakpoint numbers (separated by spaces) as arguments or no
          argument at all if you want to disable every breakpoint.
        DESCRIPTION
      end

      def self.short_description
        "Disable all or specific breakpoints."
      end

      def execute
        enable_disable_breakpoints("disable", @match[1])
      end
    end
  end
end
