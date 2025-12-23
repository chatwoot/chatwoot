# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for cops checking if and unless expressions.
    module OnNormalIfUnless
      def on_if(node)
        return if node.modifier_form? || node.ternary?

        on_normal_if_unless(node)
      end
    end
  end
end
