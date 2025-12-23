# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for uses of "*" as a substitute for _join_.
      #
      # Not all cases can reliably checked, due to Ruby's dynamic
      # types, so we consider only cases when the first argument is an
      # array literal or the second is a string literal.
      #
      # @example
      #
      #   # bad
      #   %w(foo bar baz) * ","
      #
      #   # good
      #   %w(foo bar baz).join(",")
      #
      class ArrayJoin < Base
        extend AutoCorrector

        MSG = 'Favor `Array#join` over `Array#*`.'
        RESTRICT_ON_SEND = %i[*].freeze

        # @!method join_candidate?(node)
        def_node_matcher :join_candidate?, '(send $array :* $str)'

        def on_send(node)
          return unless (array, join_arg = join_candidate?(node))

          add_offense(node.loc.selector) do |corrector|
            corrector.replace(node, "#{array.source}.join(#{join_arg.source})")
          end
        end
      end
    end
  end
end
