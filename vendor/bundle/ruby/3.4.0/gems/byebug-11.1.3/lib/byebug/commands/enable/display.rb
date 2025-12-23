# frozen_string_literal: true

require_relative "../../helpers/toggle"

module Byebug
  #
  # Reopens the +enable+ command to define the +display+ subcommand
  #
  class EnableCommand < Command
    #
    # Enables all or specific displays
    #
    class DisplayCommand < Command
      include Helpers::ToggleHelper

      self.allow_in_post_mortem = true

      def self.regexp
        /^\s* d(?:isplay)? (?:\s+ (.+))? \s*$/x
      end

      def self.description
        <<-DESCRIPTION
          en[able] d[isplay][ <id1> <id2> .. <idn>]

          #{short_description}

          Arguments are the code numbers of the expressions to enable. Do "info
          display" to see the current list of code numbers. If no arguments are
          specified, all displays are enabled.
        DESCRIPTION
      end

      def self.short_description
        "Enables expressions to be displayed when program stops."
      end

      def execute
        enable_disable_display("enable", @match[1])
      end
    end
  end
end
