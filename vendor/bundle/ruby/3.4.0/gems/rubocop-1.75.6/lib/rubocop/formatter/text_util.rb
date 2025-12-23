# frozen_string_literal: true

module RuboCop
  module Formatter
    # Common logic for UI texts.
    module TextUtil
      module_function

      def pluralize(number, thing, options = {})
        if number.zero? && options[:no_for_zero]
          "no #{thing}s"
        elsif number == 1
          "1 #{thing}"
        else
          "#{number} #{thing}s"
        end
      end
    end
  end
end
