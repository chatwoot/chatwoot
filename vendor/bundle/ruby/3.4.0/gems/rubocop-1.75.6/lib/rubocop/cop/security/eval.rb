# frozen_string_literal: true

module RuboCop
  module Cop
    module Security
      # Checks for the use of `Kernel#eval` and `Binding#eval`.
      #
      # @example
      #
      #   # bad
      #
      #   eval(something)
      #   binding.eval(something)
      class Eval < Base
        MSG = 'The use of `eval` is a serious security risk.'
        RESTRICT_ON_SEND = %i[eval].freeze

        # @!method eval?(node)
        def_node_matcher :eval?, <<~PATTERN
          (send {nil? (send nil? :binding)} :eval $!str ...)
        PATTERN

        def on_send(node)
          eval?(node) do |code|
            return if code.dstr_type? && code.recursive_literal?

            add_offense(node.loc.selector)
          end
        end
      end
    end
  end
end
