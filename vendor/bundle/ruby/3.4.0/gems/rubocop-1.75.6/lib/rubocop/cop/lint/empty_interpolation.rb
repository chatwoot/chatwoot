# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for empty interpolation.
      #
      # @example
      #
      #   # bad
      #   "result is #{}"
      #
      #   # good
      #   "result is #{some_result}"
      class EmptyInterpolation < Base
        include Interpolation
        extend AutoCorrector

        MSG = 'Empty interpolation detected.'

        def on_interpolation(begin_node)
          return unless begin_node.children.empty?

          add_offense(begin_node) { |corrector| corrector.remove(begin_node) }
        end
      end
    end
  end
end
