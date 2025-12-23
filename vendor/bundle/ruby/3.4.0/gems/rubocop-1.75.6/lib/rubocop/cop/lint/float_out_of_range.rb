# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Identifies `Float` literals which are, like, really really really
      # really really really really really big. Too big. No-one needs Floats
      # that big. If you need a float that big, something is wrong with you.
      #
      # @example
      #
      #   # bad
      #   float = 3.0e400
      #
      #   # good
      #   float = 42.9
      class FloatOutOfRange < Base
        MSG = 'Float out of range.'

        def on_float(node)
          return unless node.value.infinite? || (node.value.zero? && /[1-9]/.match?(node.source))

          add_offense(node)
        end
      end
    end
  end
end
