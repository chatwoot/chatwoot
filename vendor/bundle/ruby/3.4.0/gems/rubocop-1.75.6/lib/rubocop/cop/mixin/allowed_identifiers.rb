# frozen_string_literal: true

module RuboCop
  module Cop
    # This module encapsulates the ability to allow certain identifiers in a cop.
    module AllowedIdentifiers
      SIGILS = '@$' # if a variable starts with a sigil it will be removed

      def allowed_identifier?(name)
        !allowed_identifiers.empty? && allowed_identifiers.include?(name.to_s.delete(SIGILS))
      end

      def allowed_identifiers
        cop_config.fetch('AllowedIdentifiers') { [] }
      end
    end
  end
end
