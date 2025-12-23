# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks that exactly one space is used between a method name and the
      # first argument for method calls without parentheses.
      #
      # Alternatively, extra spaces can be added to align the argument with
      # something on a preceding or following line, if the AllowForAlignment
      # config parameter is true.
      #
      # @example
      #   # bad
      #   something  x
      #   something   y, z
      #   something'hello'
      #
      #   # good
      #   something x
      #   something y, z
      #   something 'hello'
      #
      class SpaceBeforeFirstArg < Base
        include PrecedingFollowingAlignment
        include RangeHelp
        extend AutoCorrector

        MSG = 'Put one space between the method name and the first argument.'

        def self.autocorrect_incompatible_with
          [Style::MethodCallWithArgsParentheses]
        end

        def on_send(node)
          return unless regular_method_call_with_arguments?(node)
          return if node.parenthesized?

          first_arg = node.first_argument.source_range
          first_arg_with_space = range_with_surrounding_space(first_arg, side: :left)
          space = range_between(first_arg_with_space.begin_pos, first_arg.begin_pos)
          return if space.length == 1
          return unless expect_params_after_method_name?(node)

          add_offense(space) { |corrector| corrector.replace(space, ' ') }
        end
        alias on_csend on_send

        private

        def regular_method_call_with_arguments?(node)
          node.arguments? && !node.operator_method? && !node.setter_method?
        end

        def expect_params_after_method_name?(node)
          return true if no_space_between_method_name_and_first_argument?(node)

          first_arg = node.first_argument

          same_line?(first_arg, node) &&
            !(allow_for_alignment? && aligned_with_something?(first_arg.source_range))
        end

        def no_space_between_method_name_and_first_argument?(node)
          end_pos_of_method_name = node.loc.selector.end_pos
          begin_pos_of_argument = node.first_argument.source_range.begin_pos

          end_pos_of_method_name == begin_pos_of_argument
        end
      end
    end
  end
end
