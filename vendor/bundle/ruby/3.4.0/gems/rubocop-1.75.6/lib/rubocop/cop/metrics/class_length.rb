# frozen_string_literal: true

module RuboCop
  module Cop
    module Metrics
      # Checks if the length of a class exceeds some maximum value.
      # Comment lines can optionally be ignored.
      # The maximum allowed length is configurable.
      #
      # You can set constructs you want to fold with `CountAsOne`.
      #
      # Available are: 'array', 'hash', 'heredoc', and 'method_call'.
      # Each construct will be counted as one line regardless of its actual size.
      #
      # NOTE: This cop also applies for `Struct` definitions.
      #
      # @example CountAsOne: ['array', 'hash', 'heredoc', 'method_call']
      #
      #   class Foo
      #     ARRAY = [         # +1
      #       1,
      #       2
      #     ]
      #
      #     HASH = {          # +1
      #       key: 'value'
      #     }
      #
      #     MSG = <<~HEREDOC  # +1
      #       Heredoc
      #       content.
      #     HEREDOC
      #
      #     foo(              # +1
      #       1,
      #       2
      #     )
      #   end                 # 4 points
      #
      class ClassLength < Base
        include CodeLength

        def on_class(node)
          check_code_length(node)
        end

        def on_sclass(node)
          return if node.each_ancestor(:class).any?

          on_class(node)
        end

        def on_casgn(node)
          block_node = node.expression || find_expression_within_parent(node.parent)

          return unless block_node.respond_to?(:class_definition?) && block_node.class_definition?

          check_code_length(block_node)
        end

        private

        def message(length, max_length)
          format('Class has too many lines. [%<length>d/%<max>d]', length: length, max: max_length)
        end

        def find_expression_within_parent(parent)
          if parent&.assignment?
            parent.expression
          elsif parent&.parent&.masgn_type?
            parent.parent.expression
          end
        end
      end
    end
  end
end
