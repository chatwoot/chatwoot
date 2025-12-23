# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Check for chained `dig` calls that can be collapsed into a single `dig`.
      #
      # @safety
      #   This cop is unsafe because it cannot be guaranteed that the receiver
      #   is an `Enumerable` or does not have a nonstandard implementation
      #   of `dig`.
      #
      # @example
      #   # bad
      #   x.dig(:foo).dig(:bar).dig(:baz)
      #   x.dig(:foo, :bar).dig(:baz)
      #   x.dig(:foo, :bar)&.dig(:baz)
      #
      #   # good
      #   x.dig(:foo, :bar, :baz)
      #
      #   # good - `dig`s cannot be combined
      #   x.dig(:foo).bar.dig(:baz)
      #
      class DigChain < Base
        extend AutoCorrector
        include CommentsHelp
        include DigHelp

        MSG = 'Use `%<replacement>s` instead of chaining.'
        RESTRICT_ON_SEND = %i[dig].freeze

        def on_send(node)
          return if ignored_node?(node)
          return unless node.loc.dot
          return unless dig?(node)

          range, arguments = inspect_chain(node)
          return if invalid_arguments?(arguments)
          return unless range

          register_offense(node, range, arguments)
        end
        alias on_csend on_send

        private

        # Walk up the method chain while the receiver is `dig` with arguments.
        def inspect_chain(node)
          arguments = node.arguments.dup
          end_range = node.source_range.end

          while dig?(node = node.receiver)
            begin_range = node.loc.selector
            arguments.unshift(*node.arguments)
            ignore_node(node)
          end

          return unless begin_range

          [begin_range.join(end_range), arguments]
        end

        def invalid_arguments?(arguments)
          # If any of the arguments are arguments forwarding (`...`), it can only be the
          # first argument, or else the resulting code will have a syntax error.

          return false unless arguments&.any?

          forwarded_args_index = arguments.index(&:forwarded_args_type?)
          forwarded_args_index && forwarded_args_index < (arguments.size - 1)
        end

        def register_offense(node, range, arguments)
          arguments = arguments.map(&:source).join(', ')
          replacement = "dig(#{arguments})"

          add_offense(range, message: format(MSG, replacement: replacement)) do |corrector|
            corrector.replace(range, replacement)

            comments_in_range(node).reverse_each do |comment|
              corrector.insert_before(node, "#{comment.source}\n")
            end
          end
        end
      end
    end
  end
end
