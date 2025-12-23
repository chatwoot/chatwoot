module Hashie
  module Extensions
    module KeyConflictWarning
      class CannotDisableMashWarnings < StandardError
        def initialize
          super(
            'You cannot disable warnings on the base Mash class. ' \
            'Please subclass the Mash and disable it in the subclass.'
          )
        end
      end

      # Disable the logging of warnings based on keys conflicting keys/methods
      #
      # @api semipublic
      # @return [void]
      def disable_warnings(*method_keys)
        raise CannotDisableMashWarnings if self == Hashie::Mash
        if method_keys.any?
          disabled_warnings.concat(method_keys).tap(&:flatten!).uniq!
        else
          disabled_warnings.clear
        end

        @disable_warnings = true
      end

      # Checks whether this class disables warnings for conflicting keys/methods
      #
      # @api semipublic
      # @return [Boolean]
      def disable_warnings?(method_key = nil)
        return disabled_warnings.include?(method_key) if disabled_warnings.any? && method_key
        @disable_warnings ||= false
      end

      # Returns an array of methods that this class disables warnings for.
      #
      # @api semipublic
      # @return [Boolean]
      def disabled_warnings
        @_disabled_warnings ||= []
      end

      # Inheritance hook that sets class configuration when inherited.
      #
      # @api semipublic
      # @return [void]
      def inherited(subclass)
        super
        subclass.disable_warnings(disabled_warnings) if disable_warnings?
      end
    end
  end
end
