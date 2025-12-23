# frozen_string_literal: true

require "pathname"
require_relative "../command"
require_relative "../helpers/frame"
require_relative "../helpers/parse"

module Byebug
  #
  # Move the current frame up in the backtrace.
  #
  class UpCommand < Command
    include Helpers::FrameHelper
    include Helpers::ParseHelper

    self.allow_in_post_mortem = true

    def self.regexp
      /^\s* up (?:\s+(\S+))? \s*$/x
    end

    def self.description
      <<-DESCRIPTION
        up[ count]

        #{short_description}

        Use the "bt" command to find out where you want to go.
      DESCRIPTION
    end

    def self.short_description
      "Moves to a higher frame in the stack trace"
    end

    def execute
      pos, err = parse_steps(@match[1], "Up")
      return errmsg(err) unless pos

      jump_frames(pos)

      ListCommand.new(processor).execute if Setting[:autolist]
    end
  end
end
