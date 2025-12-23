# frozen_string_literal: true

module RuboCop
  class ConfigObsoletion
    # Encapsulation of a ConfigObsoletion rule for changing a parameter
    # @api private
    class ChangedParameter < ParameterRule
      BASE_MESSAGE = 'obsolete parameter `%<parameter>s` (for `%<cop>s`) found in %<path>s'

      def message
        base = format(BASE_MESSAGE, parameter: parameter, cop: cop, path: smart_loaded_path)

        if alternative
          "#{base}\n`#{parameter}` has been renamed to `#{alternative.chomp}`."
        elsif alternatives
          "#{base}\n`#{parameter}` has been renamed to #{to_sentence(alternatives.map do |item|
                                                                       "`#{item}`"
                                                                     end,
                                                                     connector: 'and/or')}."
        else
          "#{base}\n#{reason.chomp}"
        end
      end
    end
  end
end
