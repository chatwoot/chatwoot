# frozen_string_literal: true

module RuboCop
  module Cop
    module Naming
      # Checks whether constant names are written using
      # SCREAMING_SNAKE_CASE.
      #
      # To avoid false positives, it ignores cases in which we cannot know
      # for certain the type of value that would be assigned to a constant.
      #
      # @example
      #   # bad
      #   InchInCm = 2.54
      #   INCHinCM = 2.54
      #   Inch_In_Cm = 2.54
      #
      #   # good
      #   INCH_IN_CM = 2.54
      class ConstantName < Base
        MSG = 'Use SCREAMING_SNAKE_CASE for constants.'
        # Use POSIX character classes, so we allow accented characters rather
        # than just standard ASCII characters
        SNAKE_CASE = /^[[:digit:][:upper:]_]+$/.freeze

        # @!method class_or_struct_return_method?(node)
        def_node_matcher :class_or_struct_return_method?, <<~PATTERN
          (send
            (const _ {:Class :Struct}) :new
            ...)
        PATTERN

        def on_casgn(node)
          value = if node.parent&.or_asgn_type?
                    node.parent.expression
                  else
                    node.expression
                  end

          # We cannot know the result of method calls like
          # NewClass = something_that_returns_a_class
          # It's also ok to assign a class constant another class constant,
          # `Class.new(...)` or `Struct.new(...)`
          # SomeClass = SomeOtherClass
          # SomeClass = Class.new(...)
          # SomeClass = Struct.new(...)
          return if allowed_assignment?(value)
          return if SNAKE_CASE.match?(node.name)

          add_offense(node.loc.name)
        end

        private

        def allowed_assignment?(value)
          (value && %i[block const casgn].include?(value.type)) ||
            allowed_method_call_on_rhs?(value) ||
            class_or_struct_return_method?(value) ||
            allowed_conditional_expression_on_rhs?(value)
        end

        def allowed_method_call_on_rhs?(node)
          node&.send_type? && (node.receiver.nil? || !literal_receiver?(node))
        end

        # @!method literal_receiver?(node)
        def_node_matcher :literal_receiver?, <<~PATTERN
          {(send literal? ...)
           (send (begin literal?) ...)}
        PATTERN

        def allowed_conditional_expression_on_rhs?(node)
          node&.if_type? && contains_constant?(node)
        end

        def contains_constant?(node)
          node.branches.compact.any?(&:const_type?)
        end
      end
    end
  end
end
