# frozen_string_literal: true

require "pathname"
require_relative "../command"
require_relative "../helpers/frame"
require_relative "../helpers/parse"

module Byebug
  #
  # Move to specific frames in the backtrace.
  #
  class FrameCommand < Command
    include Helpers::FrameHelper
    include Helpers::ParseHelper

    self.allow_in_post_mortem = true

    def self.regexp
      /^\s* f(?:rame)? (?:\s+(\S+))? \s*$/x
    end

    def self.description
      <<-DESCRIPTION
        f[rame][ frame-number]

        #{short_description}

        If a frame number has been specified, to moves to that frame. Otherwise
        it moves to the newest frame.

        A negative number indicates position from the other end, so "frame -1"
        moves to the oldest frame, and "frame 0" moves to the newest frame.

        Without an argument, the command prints the current stack frame. Since
        the current position is redisplayed, it may trigger a resyncronization
        if there is a front end also watching over things.

        Use the "bt" command to find out where you want to go.
      DESCRIPTION
    end

    def self.short_description
      "Moves to a frame in the call stack"
    end

    def execute
      return print(pr("frame.line", context.frame.to_hash)) unless @match[1]

      pos, err = get_int(@match[1], "Frame")
      return errmsg(err) unless pos

      switch_to_frame(pos)

      ListCommand.new(processor).execute if Setting[:autolist]
    end
  end
end
