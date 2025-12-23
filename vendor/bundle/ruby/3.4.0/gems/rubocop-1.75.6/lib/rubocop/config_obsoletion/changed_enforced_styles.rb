# frozen_string_literal: true

module RuboCop
  class ConfigObsoletion
    # Encapsulation of a ConfigObsoletion rule for changing a parameter
    # @api private
    class ChangedEnforcedStyles < ParameterRule
      BASE_MESSAGE = 'obsolete `%<parameter>s: %<value>s` (for `%<cop>s`) found in %<path>s'

      def violated?
        super && config[cop][parameter] == value
      end

      def message
        base = format(BASE_MESSAGE,
                      parameter: parameter, value: value, cop: cop, path: smart_loaded_path)

        if alternative
          "#{base}\n`#{parameter}: #{value}` has been renamed to " \
            "`#{parameter}: #{alternative.chomp}`."
        else
          "#{base}\n#{reason.chomp}"
        end
      end

      private

      def value
        metadata['value']
      end
    end
  end
end
