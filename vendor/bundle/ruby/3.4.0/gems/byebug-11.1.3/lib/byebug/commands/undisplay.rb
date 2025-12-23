# frozen_string_literal: true

require_relative "../command"
require_relative "../helpers/parse"

module Byebug
  #
  # Remove expressions from display list.
  #
  class UndisplayCommand < Command
    include Helpers::ParseHelper

    self.allow_in_post_mortem = true

    def self.regexp
      /^\s* undisp(?:lay)? (?:\s+(\S+))? \s*$/x
    end

    def self.description
      <<-DESCRIPTION
        undisp[lay][ nnn]

        #{short_description}

        Arguments are the code numbers of the expressions to stop displaying. No
        argument means cancel all automatic-display expressions. Type "info
        display" to see the current list of code numbers.
      DESCRIPTION
    end

    def self.short_description
      "Stops displaying all or some expressions when program stops"
    end

    def execute
      if @match[1]
        pos, err = get_int(@match[1], "Undisplay", 1, Byebug.displays.size)
        return errmsg(err) unless err.nil?

        last_display = Byebug.displays[pos - 1]
        return errmsg(pr("display.errors.undefined", expr: pos)) unless last_display

        last_display[0] = nil
      else
        return unless confirm(pr("display.confirmations.clear_all"))

        Byebug.displays.each { |d| d[0] = false }
      end
    end
  end
end
