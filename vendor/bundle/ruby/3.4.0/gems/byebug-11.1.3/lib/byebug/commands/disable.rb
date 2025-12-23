# frozen_string_literal: true

require_relative "../subcommands"

require_relative "../commands/disable/breakpoints"
require_relative "../commands/disable/display"

module Byebug
  #
  # Disabling custom display expressions or breakpoints.
  #
  class DisableCommand < Command
    include Subcommands

    self.allow_in_post_mortem = true

    def self.regexp
      /^\s* dis(?:able)? (?:\s+ (.+))? \s*$/x
    end

    def self.description
      <<-DESCRIPTION
        dis[able][[ breakpoints| display)][ n1[ n2[ ...[ nn]]]]]

        #{short_description}
      DESCRIPTION
    end

    def self.short_description
      "Disables breakpoints or displays"
    end
  end
end
