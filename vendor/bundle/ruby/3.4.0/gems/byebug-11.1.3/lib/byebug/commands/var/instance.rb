# frozen_string_literal: true

require_relative "../../helpers/var"

module Byebug
  #
  # Reopens the +var+ command to define the +instance+ subcommand
  #
  class VarCommand < Command
    #
    # Shows instance variables
    #
    class InstanceCommand < Command
      include Helpers::VarHelper

      self.allow_in_post_mortem = true

      def self.regexp
        /^\s* i(?:nstance)? (?:\s+ (.+))? \s*$/x
      end

      def self.description
        <<-DESCRIPTION
          v[ar] i[nstance][ <object>]

          #{short_description}
        DESCRIPTION
      end

      def self.short_description
        "Shows instance variables of self or a specific object."
      end

      def execute
        var_instance(@match[1])
      end
    end
  end
end
