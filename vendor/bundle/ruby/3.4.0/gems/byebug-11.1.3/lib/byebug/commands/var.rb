# frozen_string_literal: true

require_relative "../subcommands"

require_relative "var/all"
require_relative "var/args"
require_relative "var/const"
require_relative "var/instance"
require_relative "var/local"
require_relative "var/global"

module Byebug
  #
  # Shows variables and its values
  #
  class VarCommand < Command
    include Subcommands

    self.allow_in_post_mortem = true

    def self.regexp
      /^\s* v(?:ar)? (?:\s+ (.+))? \s*$/x
    end

    def self.description
      <<-DESCRIPTION
        [v]ar <subcommand>

        #{short_description}
      DESCRIPTION
    end

    def self.short_description
      "Shows variables and its values"
    end
  end
end
