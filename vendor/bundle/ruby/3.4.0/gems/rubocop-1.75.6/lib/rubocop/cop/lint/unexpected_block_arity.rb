# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for a block that is known to need more positional
      # block arguments than are given (by default this is configured for
      # `Enumerable` methods needing 2 arguments). Optional arguments are allowed,
      # although they don't generally make sense as the default value will
      # be used. Blocks that have no receiver, or take splatted arguments
      # (ie. `*args`) are always accepted.
      #
      # Keyword arguments (including `**kwargs`) do not get counted towards
      # this, as they are not used by the methods in question.
      #
      # Method names and their expected arity can be configured like this:
      #
      # [source,yaml]
      # ----
      # Methods:
      #   inject: 2
      #   reduce: 2
      # ----
      #
      # @safety
      #  This cop matches for method names only and hence cannot tell apart
      #  methods with same name in different classes, which may lead to a
      #  false positive.
      #
      # @example
      #   # bad
      #   values.reduce {}
      #   values.min { |a| a }
      #   values.sort { |a; b| a + b }
      #
      #   # good
      #   values.reduce { |memo, obj| memo << obj }
      #   values.min { |a, b| a <=> b }
      #   values.sort { |*x| x[0] <=> x[1] }
      #
      class UnexpectedBlockArity < Base
        MSG = '`%<method>s` expects at least %<expected>i positional arguments, got %<actual>i.'

        def on_block(node)
          return if acceptable?(node)

          expected = expected_arity(node.method_name)
          actual = arg_count(node)
          return if actual >= expected

          message = format(MSG, method: node.method_name, expected: expected, actual: actual)
          add_offense(node, message: message)
        end

        alias on_numblock on_block
        alias on_itblock on_block

        private

        def methods
          cop_config.fetch('Methods', [])
        end

        def acceptable?(node)
          !(included_method?(node.method_name) && node.receiver)
        end

        def included_method?(name)
          methods.key?(name.to_s)
        end

        def expected_arity(method)
          cop_config['Methods'][method.to_s]
        end

        def arg_count(node)
          return node.children[1] if node.numblock_type? # the maximum numbered param for the block
          return 1 if node.itblock_type? # `it` block parameter is always one

          # Only `arg`, `optarg` and `mlhs` (destructuring) count as arguments that
          # can be used. Keyword arguments are not used for these methods so are
          # ignored.
          node.arguments.count do |arg|
            return Float::INFINITY if arg.restarg_type?

            arg.type?(:arg, :optarg, :mlhs)
          end
        end
      end
    end
  end
end
