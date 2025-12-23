# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Enforces the presence (default) or absence of parentheses in
      # method calls containing arguments.
      #
      # In the default style (require_parentheses), macro methods are allowed.
      # Additional methods can be added to the `AllowedMethods` or
      # `AllowedPatterns` list. These options are valid only in the default
      # style. Macros can be included by either setting `IgnoreMacros` to false
      # or adding specific macros to the `IncludedMacros` list.
      #
      # Precedence of options is as follows:
      #
      # 1. `AllowedMethods`
      # 2. `AllowedPatterns`
      # 3. `IncludedMacros`
      #
      # If a method is listed in both `IncludedMacros` and `AllowedMethods`,
      # then the latter takes precedence (that is, the method is allowed).
      #
      # In the alternative style (omit_parentheses), there are three additional
      # options.
      #
      # 1. `AllowParenthesesInChaining` is `false` by default. Setting it to
      #    `true` allows the presence of parentheses in the last call during
      #    method chaining.
      #
      # 2. `AllowParenthesesInMultilineCall` is `false` by default. Setting it
      #     to `true` allows the presence of parentheses in multi-line method
      #     calls.
      #
      # 3. `AllowParenthesesInCamelCaseMethod` is `false` by default. This
      #     allows the presence of parentheses when calling a method whose name
      #     begins with a capital letter and which has no arguments. Setting it
      #     to `true` allows the presence of parentheses in such a method call
      #     even with arguments.
      #
      # NOTE: The style of `omit_parentheses` allows parentheses in cases where
      # omitting them results in ambiguous or syntactically incorrect code.
      #
      # Non-exhaustive list of examples:
      #
      # - Parentheses are required allowed in method calls with arguments inside
      #   literals, logical operators, setting default values in position and
      #   keyword arguments, chaining and more.
      # - Parentheses are allowed in method calls with arguments inside
      #   operators to avoid ambiguity.
      #   triple-dot syntax introduced in Ruby 2.7 as omitting them starts an
      #   endless range.
      # - Parentheses are allowed when forwarding arguments with the
      #   triple-dot syntax introduced in Ruby 2.7 as omitting them starts an
      #   endless range.
      # - Parentheses are required in calls with arguments when inside an
      #   endless method definition introduced in Ruby 3.0.
      # - Ruby 3.1's hash omission syntax allows parentheses if the method call
      #   is in conditionals and requires parentheses if the call
      #   is not the value-returning expression. See
      #   https://bugs.ruby-lang.org/issues/18396.
      # - Parentheses are required in anonymous arguments, keyword arguments
      #   and block passing in Ruby 3.2.
      # - Parentheses are required when the first argument is a beginless range or
      #   the last argument is an endless range.
      #
      # @example EnforcedStyle: require_parentheses (default)
      #
      #   # bad
      #   array.delete e
      #
      #   # good
      #   array.delete(e)
      #
      #   # good
      #   # Operators don't need parens
      #   foo == bar
      #
      #   # good
      #   # Setter methods don't need parens
      #   foo.bar = baz
      #
      #   # okay with `puts` listed in `AllowedMethods`
      #   puts 'test'
      #
      #   # okay with `^assert` listed in `AllowedPatterns`
      #   assert_equal 'test', x
      #
      # @example EnforcedStyle: omit_parentheses
      #
      #   # bad
      #   array.delete(e)
      #
      #   # good
      #   array.delete e
      #
      #   # bad
      #   action.enforce(strict: true)
      #
      #   # good
      #   action.enforce strict: true
      #
      #   # good
      #   # Parentheses are allowed for code that can be ambiguous without
      #   # them.
      #   action.enforce(condition) || other_condition
      #
      #   # good
      #   # Parentheses are allowed for calls that won't produce valid Ruby
      #   # without them.
      #   yield path, File.basename(path)
      #
      #   # good
      #   # Omitting the parentheses in Ruby 3.1 hash omission syntax can lead
      #   # to ambiguous code. We allow them in conditionals and non-last
      #   # expressions. See https://bugs.ruby-lang.org/issues/18396
      #   if meets(criteria:, action:)
      #     safe_action(action) || dangerous_action(action)
      #   end
      #
      # @example IgnoreMacros: true (default)
      #
      #   # good
      #   class Foo
      #     bar :baz
      #   end
      #
      # @example IgnoreMacros: false
      #
      #   # bad
      #   class Foo
      #     bar :baz
      #   end
      #
      # @example AllowParenthesesInMultilineCall: false (default)
      #
      #   # bad
      #   foo.enforce(
      #     strict: true
      #   )
      #
      #   # good
      #   foo.enforce \
      #     strict: true
      #
      # @example AllowParenthesesInMultilineCall: true
      #
      #   # good
      #   foo.enforce(
      #     strict: true
      #   )
      #
      #   # good
      #   foo.enforce \
      #     strict: true
      #
      # @example AllowParenthesesInChaining: false (default)
      #
      #   # bad
      #   foo().bar(1)
      #
      #   # good
      #   foo().bar 1
      #
      # @example AllowParenthesesInChaining: true
      #
      #   # good
      #   foo().bar(1)
      #
      #   # good
      #   foo().bar 1
      #
      # @example AllowParenthesesInCamelCaseMethod: false (default)
      #
      #   # bad
      #   Array(1)
      #
      #   # good
      #   Array 1
      #
      # @example AllowParenthesesInCamelCaseMethod: true
      #
      #   # good
      #   Array(1)
      #
      #   # good
      #   Array 1
      #
      # @example AllowParenthesesInStringInterpolation: false (default)
      #
      #   # bad
      #   "#{t('this.is.bad')}"
      #
      #   # good
      #   "#{t 'this.is.better'}"
      #
      # @example AllowParenthesesInStringInterpolation: true
      #
      #   # good
      #   "#{t('this.is.good')}"
      #
      #   # good
      #   "#{t 'this.is.also.good'}"
      class MethodCallWithArgsParentheses < Base
        require_relative 'method_call_with_args_parentheses/omit_parentheses'
        require_relative 'method_call_with_args_parentheses/require_parentheses'

        include ConfigurableEnforcedStyle
        include AllowedMethods
        include AllowedPattern
        include RequireParentheses
        include OmitParentheses
        extend AutoCorrector

        def self.autocorrect_incompatible_with
          [Style::NestedParenthesizedCalls, Style::RescueModifier]
        end

        def on_send(node)
          send(style, node) # call require_parentheses or omit_parentheses
        end
        alias on_csend on_send
        alias on_yield on_send

        private

        def args_begin(node)
          loc = node.loc
          selector = node.yield_type? ? loc.keyword : loc.selector

          resize_by = args_parenthesized?(node) ? 2 : 1
          selector.end.resize(resize_by)
        end

        def args_end(node)
          node.source_range.end
        end

        def args_parenthesized?(node)
          return false unless node.arguments.one?

          first_node = node.first_argument
          first_node.begin_type? && first_node.parenthesized_call?
        end
      end
    end
  end
end
