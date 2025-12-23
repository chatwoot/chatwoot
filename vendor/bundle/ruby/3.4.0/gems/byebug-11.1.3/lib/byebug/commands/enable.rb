# frozen_string_literal: true

require_relative "../subcommands"

require_relative "../commands/enable/breakpoints"
require_relative "../commands/enable/display"

module Byebug
  #
  # Enabling custom display expressions or breakpoints.
  #
  class EnableCommand < Command
    include Subcommands

    self.allow_in_post_mortem = true

    def self.regexp
      /^\s* en(?:able)? (?:\s+ (.+))? \s*$/x
    end

    def self.description
      <<-DESCRIPTION
        en[able][[ b[reakpoints]| d[isplay])][ n1[ n2[ ...[ nn]]]]]

        #{short_description}
      DESCRIPTION
    end

    def self.short_description
      "Enables breakpoints or displays"
    end
  end
end
