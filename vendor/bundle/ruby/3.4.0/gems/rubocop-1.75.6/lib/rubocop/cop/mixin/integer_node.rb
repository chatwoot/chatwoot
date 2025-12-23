# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for checking integer nodes.
    module IntegerNode
      private

      def integer_part(node)
        node.source.sub(/^[+-]/, '').split(/[eE.]/, 2).first
      end
    end
  end
end
