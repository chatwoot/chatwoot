# frozen_string_literal: true

require_relative "../../helpers/var"

module Byebug
  #
  # Reopens the +var+ command to define the +all+ subcommand
  #
  class VarCommand < Command
    #
    # Shows global, instance and local variables
    #
    class AllCommand < Command
      include Helpers::VarHelper

      self.allow_in_post_mortem = true

      def self.regexp
        /^\s* a(?:ll)? \s*$/x
      end

      def self.description
        <<-DESCRIPTION
          v[ar] a[ll]

          #{short_description}
        DESCRIPTION
      end

      def self.short_description
        "Shows local, global and instance variables of self."
      end

      def execute
        var_global
        var_instance("self")
        var_local
      end
    end
  end
end
