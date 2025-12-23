# frozen_string_literal: true

require_relative "../subcommands"

require_relative "../commands/info/breakpoints"
require_relative "../commands/info/display"
require_relative "../commands/info/file"
require_relative "../commands/info/line"
require_relative "../commands/info/program"

module Byebug
  #
  # Shows info about different aspects of the debugger.
  #
  class InfoCommand < Command
    include Subcommands

    self.allow_in_control = true
    self.allow_in_post_mortem = true

    def self.regexp
      /^\s* i(?:nfo)? (?:\s+ (.+))? \s*$/x
    end

    def self.description
      <<-DESCRIPTION
        info[ subcommand]

        #{short_description}
      DESCRIPTION
    end

    def self.short_description
      "Shows several informations about the program being debugged"
    end
  end
end
