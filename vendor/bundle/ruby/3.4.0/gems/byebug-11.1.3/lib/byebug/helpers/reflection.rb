# frozen_string_literal: true

module Byebug
  module Helpers
    #
    # Reflection utilitie
    #
    module ReflectionHelper
      #
      # List of "command" classes in the including module
      #
      def commands
        constants(false)
          .map { |const| const_get(const, false) }
          .select { |c| c.is_a?(Class) && c.name =~ /[a-z]Command$/ }
      end
    end
  end
end
