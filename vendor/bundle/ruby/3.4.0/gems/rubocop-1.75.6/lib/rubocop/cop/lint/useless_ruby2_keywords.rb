# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Looks for `ruby2_keywords` calls for methods that do not need it.
      #
      # `ruby2_keywords` should only be called on methods that accept an argument splat
      # (`\*args`) but do not explicit keyword arguments (`k:` or `k: true`) or
      # a keyword splat (`**kwargs`).
      #
      # @example
      #   # good (splat argument without keyword arguments)
      #   ruby2_keywords def foo(*args); end
      #
      #   # bad (no arguments)
      #   ruby2_keywords def foo; end
      #
      #   # good
      #   def foo; end
      #
      #   # bad (positional argument)
      #   ruby2_keywords def foo(arg); end
      #
      #   # good
      #   def foo(arg); end
      #
      #   # bad (double splatted argument)
      #   ruby2_keywords def foo(**args); end
      #
      #   # good
      #   def foo(**args); end
      #
      #   # bad (keyword arguments)
      #   ruby2_keywords def foo(i:, j:); end
      #
      #   # good
      #   def foo(i:, j:); end
      #
      #   # bad (splat argument with keyword arguments)
      #   ruby2_keywords def foo(*args, i:, j:); end
      #
      #   # good
      #   def foo(*args, i:, j:); end
      #
      #   # bad (splat argument with double splat)
      #   ruby2_keywords def foo(*args, **kwargs); end
      #
      #   # good
      #   def foo(*args, **kwargs); end
      #
      #   # bad (ruby2_keywords given a symbol)
      #   def foo; end
      #   ruby2_keywords :foo
      #
      #   # good
      #   def foo; end
      #
      #   # bad (ruby2_keywords with dynamic method)
      #   define_method(:foo) { |arg| }
      #   ruby2_keywords :foo
      #
      #   # good
      #   define_method(:foo) { |arg| }
      #
      class UselessRuby2Keywords < Base
        MSG = '`ruby2_keywords` is unnecessary for method `%<method_name>s`.'
        RESTRICT_ON_SEND = %i[ruby2_keywords].freeze

        # Looks for statically or dynamically defined methods with a given name
        # @!method method_definition(node, method_name)
        def_node_matcher :method_definition, <<~PATTERN
          {
            (def %1 ...)
            (any_block (send _ :define_method (sym %1)) ...)
          }
        PATTERN

        def on_send(node)
          return unless (first_argument = node.first_argument)

          if first_argument.def_type?
            inspect_def(node, first_argument)
          elsif node.first_argument.sym_type?
            inspect_sym(node, first_argument)
          end
        end

        private

        def inspect_def(node, def_node)
          return if allowed_arguments(def_node.arguments)

          add_offense(node.loc.selector, message: format(MSG, method_name: def_node.method_name))
        end

        def inspect_sym(node, sym_node)
          return unless node.parent

          method_name = sym_node.value
          definition = find_method_definition(node, method_name)

          return unless definition
          return if allowed_arguments(definition.arguments)

          add_offense(node, message: format(MSG, method_name: method_name))
        end

        def find_method_definition(node, method_name)
          node.each_ancestor.lazy.map do |ancestor|
            ancestor.each_child_node(:def, :any_block).find do |child|
              method_definition(child, method_name)
            end
          end.find(&:itself)
        end

        # `ruby2_keywords` is only allowed if there's a `restarg` and no keyword arguments
        def allowed_arguments(arguments)
          return false if arguments.empty?

          arguments.each_child_node(:restarg).any? &&
            arguments.each_child_node(:kwarg, :kwoptarg, :kwrestarg).none?
        end
      end
    end
  end
end
