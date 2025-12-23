# frozen_string_literal: true

module RuboCop
  module Cop
    module Naming
      # Makes sure that all numbered variables use the
      # configured style, snake_case, normalcase, or non_integer,
      # for their numbering.
      #
      # Additionally, `CheckMethodNames` and `CheckSymbols` configuration options
      # can be used to specify whether method names and symbols should be checked.
      # Both are enabled by default.
      #
      # @example EnforcedStyle: normalcase (default)
      #   # bad
      #   :some_sym_1
      #   variable_1 = 1
      #
      #   def some_method_1; end
      #
      #   def some_method1(arg_1); end
      #
      #   # good
      #   :some_sym1
      #   variable1 = 1
      #
      #   def some_method1; end
      #
      #   def some_method1(arg1); end
      #
      # @example EnforcedStyle: snake_case
      #   # bad
      #   :some_sym1
      #   variable1 = 1
      #
      #   def some_method1; end
      #
      #   def some_method_1(arg1); end
      #
      #   # good
      #   :some_sym_1
      #   variable_1 = 1
      #
      #   def some_method_1; end
      #
      #   def some_method_1(arg_1); end
      #
      # @example EnforcedStyle: non_integer
      #   # bad
      #   :some_sym1
      #   :some_sym_1
      #
      #   variable1 = 1
      #   variable_1 = 1
      #
      #   def some_method1; end
      #
      #   def some_method_1; end
      #
      #   def some_methodone(arg1); end
      #   def some_methodone(arg_1); end
      #
      #   # good
      #   :some_symone
      #   :some_sym_one
      #
      #   variableone = 1
      #   variable_one = 1
      #
      #   def some_methodone; end
      #
      #   def some_method_one; end
      #
      #   def some_methodone(argone); end
      #   def some_methodone(arg_one); end
      #
      #   # In the following examples, we assume `EnforcedStyle: normalcase` (default).
      #
      # @example CheckMethodNames: true (default)
      #   # bad
      #   def some_method_1; end
      #
      # @example CheckMethodNames: false
      #   # good
      #   def some_method_1; end
      #
      # @example CheckSymbols: true (default)
      #   # bad
      #   :some_sym_1
      #
      # @example CheckSymbols: false
      #   # good
      #   :some_sym_1
      #
      # @example AllowedIdentifiers: [capture3]
      #   # good
      #   expect(Open3).to receive(:capture3)
      #
      # @example AllowedPatterns: ['_v\d+\z']
      #   # good
      #   :some_sym_v1
      #
      class VariableNumber < Base
        include AllowedIdentifiers
        include ConfigurableNumbering
        include AllowedPattern

        MSG = 'Use %<style>s for %<identifier_type>s numbers.'

        def valid_name?(node, name, given_style = style)
          super || matches_allowed_pattern?(name)
        end

        def on_arg(node)
          @node = node
          return if allowed_identifier?(node.name)

          check_name(node, node.name, node.loc.name)
        end
        alias on_lvasgn on_arg
        alias on_ivasgn on_arg
        alias on_cvasgn on_arg
        alias on_gvasgn on_arg

        def on_def(node)
          @node = node
          return if allowed_identifier?(node.method_name)

          check_name(node, node.method_name, node.loc.name) if cop_config['CheckMethodNames']
        end
        alias on_defs on_def

        def on_sym(node)
          @node = node
          return if allowed_identifier?(node.value)

          check_name(node, node.value, node) if cop_config['CheckSymbols']
        end

        private

        def message(style)
          identifier_type =
            case @node.type
            when :def, :defs then 'method name'
            when :sym        then 'symbol'
            else                  'variable'
            end

          format(MSG, style: style, identifier_type: identifier_type)
        end
      end
    end
  end
end
