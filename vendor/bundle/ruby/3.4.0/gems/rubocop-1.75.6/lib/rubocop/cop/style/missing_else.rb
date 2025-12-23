# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for `if` expressions that do not have an `else` branch.
      #
      # NOTE: Pattern matching is allowed to have no `else` branch because unlike `if` and `case`,
      # it raises `NoMatchingPatternError` if the pattern doesn't match and without having `else`.
      #
      # Supported styles are: if, case, both.
      #
      # @example EnforcedStyle: both (default)
      #   # warn when an `if` or `case` expression is missing an `else` branch.
      #
      #   # bad
      #   if condition
      #     statement
      #   end
      #
      #   # bad
      #   case var
      #   when condition
      #     statement
      #   end
      #
      #   # good
      #   if condition
      #     statement
      #   else
      #     # the content of `else` branch will be determined by Style/EmptyElse
      #   end
      #
      #   # good
      #   case var
      #   when condition
      #     statement
      #   else
      #     # the content of `else` branch will be determined by Style/EmptyElse
      #   end
      #
      # @example EnforcedStyle: if
      #   # warn when an `if` expression is missing an `else` branch.
      #
      #   # bad
      #   if condition
      #     statement
      #   end
      #
      #   # good
      #   if condition
      #     statement
      #   else
      #     # the content of `else` branch will be determined by Style/EmptyElse
      #   end
      #
      #   # good
      #   case var
      #   when condition
      #     statement
      #   end
      #
      #   # good
      #   case var
      #   when condition
      #     statement
      #   else
      #     # the content of `else` branch will be determined by Style/EmptyElse
      #   end
      #
      # @example EnforcedStyle: case
      #   # warn when a `case` expression is missing an `else` branch.
      #
      #   # bad
      #   case var
      #   when condition
      #     statement
      #   end
      #
      #   # good
      #   case var
      #   when condition
      #     statement
      #   else
      #     # the content of `else` branch will be determined by Style/EmptyElse
      #   end
      #
      #   # good
      #   if condition
      #     statement
      #   end
      #
      #   # good
      #   if condition
      #     statement
      #   else
      #     # the content of `else` branch will be determined by Style/EmptyElse
      #   end
      class MissingElse < Base
        include OnNormalIfUnless
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        MSG = '`%<type>s` condition requires an `else`-clause.'
        MSG_NIL = '`%<type>s` condition requires an `else`-clause with `nil` in it.'
        MSG_EMPTY = '`%<type>s` condition requires an empty `else`-clause.'

        def on_normal_if_unless(node)
          return if case_style?
          return if unless_else_cop_enabled? && node.unless?

          check(node)
        end

        def on_case(node)
          return if if_style?

          check(node)
        end

        def on_case_match(node)
          # do nothing.
        end

        private

        def check(node)
          return if node.else?

          add_offense(node, message: format(message_template, type: node.type)) do |corrector|
            autocorrect(corrector, node)
          end
        end

        def message_template
          case empty_else_style
          when :empty
            MSG_NIL
          when :nil
            MSG_EMPTY
          else
            MSG
          end
        end

        def autocorrect(corrector, node)
          node = node.ancestors.find { |ancestor| ancestor.loc.end } unless node.loc.end

          case empty_else_style
          when :empty
            corrector.insert_before(node.loc.end, 'else; nil; ')
          when :nil
            corrector.insert_before(node.loc.end, 'else; ')
          end
        end

        def if_style?
          style == :if
        end

        def case_style?
          style == :case
        end

        def unless_else_cop_enabled?
          unless_else_config.fetch('Enabled')
        end

        def unless_else_config
          config.for_cop('Style/UnlessElse')
        end

        def empty_else_style
          return unless empty_else_config.key?('EnforcedStyle')

          empty_else_config['EnforcedStyle'].to_sym
        end

        def empty_else_config
          config.for_cop('Style/EmptyElse')
        end
      end
    end
  end
end
