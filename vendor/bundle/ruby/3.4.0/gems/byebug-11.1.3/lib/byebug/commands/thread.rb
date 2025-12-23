# frozen_string_literal: true

require_relative "../subcommands"

require_relative "../commands/thread/current"
require_relative "../commands/thread/list"
require_relative "../commands/thread/resume"
require_relative "../commands/thread/stop"
require_relative "../commands/thread/switch"

module Byebug
  #
  # Manipulation of Ruby threads
  #
  class ThreadCommand < Command
    include Subcommands

    def self.regexp
      /^\s* th(?:read)? (?:\s+ (.+))? \s*$/x
    end

    def self.description
      <<-DESCRIPTION
        th[read] <subcommand>

        #{short_description}
      DESCRIPTION
    end

    def self.short_description
      "Commands to manipulate threads"
    end
  end
end
