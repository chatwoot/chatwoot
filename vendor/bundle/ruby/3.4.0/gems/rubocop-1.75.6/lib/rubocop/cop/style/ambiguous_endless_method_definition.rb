# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Looks for endless methods inside operations of lower precedence (`and`, `or`, and
      # modifier forms of `if`, `unless`, `while`, `until`) that are ambiguous due to
      # lack of parentheses. This may lead to unexpected behavior as the code may appear
      # to use these keywords as part of the method but in fact they modify
      # the method definition itself.
      #
      # In these cases, using a normal method definition is more clear.
      #
      # @example
      #
      #   # bad
      #   def foo = true if bar
      #
      #   # good - using a non-endless method is more explicit
      #   def foo
      #     true
      #   end if bar
      #
      #   # ok - method body is explicit
      #   def foo = (true if bar)
      #
      #   # ok - method definition is explicit
      #   (def foo = true) if bar
      class AmbiguousEndlessMethodDefinition < Base
        extend TargetRubyVersion
        extend AutoCorrector
        include EndlessMethodRewriter
        include RangeHelp

        minimum_target_ruby_version 3.0

        MSG = 'Avoid using `%<keyword>s` statements with endless methods.'

        # @!method ambiguous_endless_method_body(node)
        def_node_matcher :ambiguous_endless_method_body, <<~PATTERN
          ^${
            (if _ <def _>)
            ({and or} def _)
            ({while until} _ def)
          }
        PATTERN

        def on_def(node)
          return unless node.endless?

          operation = ambiguous_endless_method_body(node)
          return unless operation

          return unless modifier_form?(operation)

          add_offense(operation, message: format(MSG, keyword: keyword(operation))) do |corrector|
            correct_to_multiline(corrector, node)
          end
        end

        private

        def modifier_form?(operation)
          return true if operation.operator_keyword?

          operation.modifier_form?
        end

        def keyword(operation)
          if operation.respond_to?(:keyword)
            operation.keyword
          else
            operation.operator
          end
        end
      end
    end
  end
end
