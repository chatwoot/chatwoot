# frozen_string_literal: true

require_relative "../command"
require_relative "../helpers/parse"

module Byebug
  #
  # Show history of byebug commands.
  #
  class HistoryCommand < Command
    include Helpers::ParseHelper

    self.allow_in_post_mortem = true

    def self.regexp
      /^\s* hist(?:ory)? (?:\s+(?<num_cmds>.+))? \s*$/x
    end

    def self.description
      <<-DESCRIPTION
        hist[ory][ num_cmds]

        #{short_description}
      DESCRIPTION
    end

    def self.short_description
      "Shows byebug's history of commands"
    end

    def execute
      history = processor.interface.history

      size, = get_int(@match[:num_cmds], "history", 1) if @match[:num_cmds]

      puts history.to_s(size)
    end
  end
end
