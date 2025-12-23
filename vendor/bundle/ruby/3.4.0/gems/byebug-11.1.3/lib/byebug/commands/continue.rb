# frozen_string_literal: true

require_relative "../command"
require_relative "../helpers/parse"

module Byebug
  #
  # Implements the continue command.
  #
  # Allows the user to continue execution until the next stopping point, a
  # specific line number or until program termination.
  #
  class ContinueCommand < Command
    include Helpers::ParseHelper

    def self.regexp
      /^\s* c(?:ont(?:inue)?)? (?:(!|\s+unconditionally|\s+\S+))? \s*$/x
    end

    def self.description
      <<-DESCRIPTION
        c[ont[inue]][ <line_number>]

        #{short_description}

        Normally the program stops at the next breakpoint. However, if the
        parameter "unconditionally" is given or the command is suffixed with
        "!", the program will run until the end regardless of any enabled
        breakpoints.
      DESCRIPTION
    end

    def self.short_description
      "Runs until program ends, hits a breakpoint or reaches a line"
    end

    def execute
      if until_line?
        num, err = get_int(modifier, "Continue", 0, nil)
        return errmsg(err) unless num

        filename = File.expand_path(frame.file)
        return errmsg(pr("continue.errors.unstopped_line", line: num)) unless Breakpoint.potential_line?(filename, num)

        Breakpoint.add(filename, num)
      end

      processor.proceed!

      Byebug.mode = :off if unconditionally?
      Byebug.stop if unconditionally? || Byebug.stoppable?
    end

    private

    def until_line?
      @match[1] && !["!", "unconditionally"].include?(modifier)
    end

    def unconditionally?
      @match[1] && ["!", "unconditionally"].include?(modifier)
    end

    def modifier
      @match[1].lstrip
    end
  end
end
