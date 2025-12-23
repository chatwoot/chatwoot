# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for redundant `if` with boolean literal branches.
      # It checks only conditions to return boolean value (`true` or `false`) for safe detection.
      # The conditions to be checked are comparison methods, predicate methods, and
      # double negation (!!).
      # `nonzero?` method is allowed by default.
      # These are customizable with `AllowedMethods` option.
      #
      # This cop targets only ``if``s with a single `elsif` or `else` branch. The following
      # code will be allowed, because it has two `elsif` branches:
      #
      # [source,ruby]
      # ----
      # if foo
      #   true
      # elsif bar > baz
      #   true
      # elsif qux > quux # Single `elsif` is warned, but two or more `elsif`s are not.
      #   true
      # else
      #   false
      # end
      # ----
      #
      # @safety
      #   Autocorrection is unsafe because there is no guarantee that all predicate methods
      #   will return a boolean value. Those methods can be allowed with `AllowedMethods` config.
      #
      # @example
      #   # bad
      #   if foo == bar
      #     true
      #   else
      #     false
      #   end
      #
      #   # bad
      #   foo == bar ? true : false
      #
      #   # good
      #   foo == bar
      #
      #   # bad
      #   if foo.do_something?
      #     true
      #   else
      #     false
      #   end
      #
      #   # good (but potentially an unsafe correction)
      #   foo.do_something?
      #
      # @example AllowedMethods: ['nonzero?'] (default)
      #   # good
      #   num.nonzero? ? true : false
      #
      class IfWithBooleanLiteralBranches < Base
        include AllowedMethods
        extend AutoCorrector

        MSG = 'Remove redundant %<keyword>s with boolean literal branches.'
        MSG_FOR_ELSIF = 'Use `else` instead of redundant `elsif` with boolean literal branches.'

        # @!method if_with_boolean_literal_branches?(node)
        def_node_matcher :if_with_boolean_literal_branches?, <<~PATTERN
          (if #return_boolean_value? <true false>)
        PATTERN
        # @!method double_negative?(node)
        def_node_matcher :double_negative?, '(send (send _ :!) :!)'

        def on_if(node)
          return if !if_with_boolean_literal_branches?(node) || multiple_elsif?(node)

          condition = node.condition
          range, keyword = offense_range_with_keyword(node, condition)

          add_offense(range, message: message(node, keyword)) do |corrector|
            replacement = replacement_condition(node, condition)

            if node.elsif?
              corrector.insert_before(node, "else\n")
              corrector.replace(node, "#{indent(node.if_branch)}#{replacement}")
            else
              corrector.replace(node, replacement)
            end
          end
        end

        private

        def multiple_elsif?(node)
          return false unless (parent = node.parent)

          parent.if_type? && parent.elsif?
        end

        def offense_range_with_keyword(node, condition)
          if node.ternary?
            range = condition.source_range.end.join(node.source_range.end)

            [range, 'ternary operator']
          else
            keyword = node.loc.keyword

            [keyword, "`#{keyword.source}`"]
          end
        end

        def message(node, keyword)
          if node.elsif?
            MSG_FOR_ELSIF
          else
            format(MSG, keyword: keyword)
          end
        end

        def return_boolean_value?(condition)
          return false unless condition

          if condition.begin_type?
            return_boolean_value?(condition.children.first)
          elsif condition.or_type?
            return_boolean_value?(condition.lhs) && return_boolean_value?(condition.rhs)
          elsif condition.and_type?
            return_boolean_value?(condition.rhs)
          else
            assume_boolean_value?(condition)
          end
        end

        def assume_boolean_value?(condition)
          return false unless condition.send_type?
          return false if allowed_method?(condition.method_name)

          condition.comparison_method? || condition.predicate_method? || double_negative?(condition)
        end

        def replacement_condition(node, condition)
          bang = '!' if opposite_condition?(node)

          if bang && require_parentheses?(condition)
            "#{bang}(#{condition.source})"
          else
            "#{bang}#{condition.source}"
          end
        end

        def opposite_condition?(node)
          (!node.unless? && node.if_branch.false_type?) ||
            (node.unless? && node.if_branch.true_type?)
        end

        def require_parentheses?(condition)
          condition.operator_keyword? || (condition.send_type? && condition.comparison_method?)
        end
      end
    end
  end
end
