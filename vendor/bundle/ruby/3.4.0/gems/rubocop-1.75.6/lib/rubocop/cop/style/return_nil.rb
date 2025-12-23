# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Enforces consistency between `return nil` and `return`.
      #
      # This cop is disabled by default. Because there seems to be a perceived semantic difference
      # between `return` and `return nil`. The former can be seen as just halting evaluation,
      # while the latter might be used when the return value is of specific concern.
      #
      # Supported styles are `return` and `return_nil`.
      #
      # @example EnforcedStyle: return (default)
      #   # bad
      #   def foo(arg)
      #     return nil if arg
      #   end
      #
      #   # good
      #   def foo(arg)
      #     return if arg
      #   end
      #
      # @example EnforcedStyle: return_nil
      #   # bad
      #   def foo(arg)
      #     return if arg
      #   end
      #
      #   # good
      #   def foo(arg)
      #     return nil if arg
      #   end
      class ReturnNil < Base
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        RETURN_MSG = 'Use `return` instead of `return nil`.'
        RETURN_NIL_MSG = 'Use `return nil` instead of `return`.'

        # @!method return_node?(node)
        def_node_matcher :return_node?, '(return)'

        # @!method return_nil_node?(node)
        def_node_matcher :return_nil_node?, '(return nil)'

        def on_return(node)
          # Check Lint/NonLocalExitFromIterator first before this cop
          node.each_ancestor(:block, :any_def) do |n|
            break if scoped_node?(n)

            send_node, args_node, _body_node = *n

            # if a proc is passed to `Module#define_method` or
            # `Object#define_singleton_method`, `return` will not cause a
            # non-local exit error
            break if define_method?(send_node)

            next if args_node.children.empty?

            return nil if chained_send?(send_node)
          end

          return if correct_style?(node)

          add_offense(node) do |corrector|
            corrected = style == :return ? 'return' : 'return nil'

            corrector.replace(node, corrected)
          end
        end

        private

        def message(_node)
          style == :return ? RETURN_MSG : RETURN_NIL_MSG
        end

        def correct_style?(node)
          (style == :return && !return_nil_node?(node)) ||
            (style == :return_nil && !return_node?(node))
        end

        def scoped_node?(node)
          node.any_def_type? || node.lambda?
        end

        # @!method chained_send?(node)
        def_node_matcher :chained_send?, '(send !nil? ...)'

        # @!method define_method?(node)
        def_node_matcher :define_method?, <<~PATTERN
          (send _ {:define_method :define_singleton_method} _)
        PATTERN
      end
    end
  end
end
