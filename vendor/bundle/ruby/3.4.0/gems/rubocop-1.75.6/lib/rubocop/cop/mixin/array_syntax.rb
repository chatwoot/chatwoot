# frozen_string_literal: true

module RuboCop
  module Cop
    # Common code for ordinary arrays with [] that can be written with %
    # syntax.
    module ArraySyntax
      private

      def bracketed_array_of?(element_type, node)
        return false unless node.square_brackets? && !node.values.empty?

        node.values.all? { |value| value.type == element_type }
      end
    end
  end
end
