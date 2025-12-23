# frozen_string_literal: true

require_relative "../../helpers/var"

module Byebug
  #
  # Reopens the +var+ command to define the +local+ subcommand
  #
  class VarCommand < Command
    #
    # Shows local variables in current scope
    #
    class LocalCommand < Command
      include Helpers::VarHelper

      self.allow_in_post_mortem = true

      def self.regexp
        /^\s* l(?:ocal)? \s*$/x
      end

      def self.description
        <<-DESCRIPTION
          v[ar] l[ocal]

          #{short_description}
        DESCRIPTION
      end

      def self.short_description
        "Shows local variables in current scope."
      end

      def execute
        var_local
      end
    end
  end
end
