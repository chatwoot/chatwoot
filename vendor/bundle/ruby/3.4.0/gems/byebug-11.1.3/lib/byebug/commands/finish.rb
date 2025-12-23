# frozen_string_literal: true

require_relative "../command"
require_relative "../helpers/parse"

module Byebug
  #
  # Implements the finish functionality.
  #
  # Allows the user to continue execution until certain frames are finished.
  #
  class FinishCommand < Command
    include Helpers::ParseHelper

    self.allow_in_post_mortem = false

    def self.regexp
      /^\s* fin(?:ish)? (?:\s+(\S+))? \s*$/x
    end

    def self.description
      <<-DESCRIPTION
        fin[ish][ n_frames]

        #{short_description}

        If no number is given, we run until the current frame returns. If a
        number of frames `n_frames` is given, then we run until `n_frames`
        return from the current position.
      DESCRIPTION
    end

    def self.short_description
      "Runs the program until frame returns"
    end

    def execute
      if @match[1]
        n_frames, err = get_int(@match[1], "finish", 0, max_frames - 1)
        return errmsg(err) unless n_frames
      else
        n_frames = 1
      end

      force = n_frames.zero? ? true : false
      context.step_out(context.frame.pos + n_frames, force)
      context.frame = 0
      processor.proceed!
    end

    private

    def max_frames
      context.stack_size - context.frame.pos
    end
  end
end
