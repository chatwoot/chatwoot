# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for variable interpolation (like "#@ivar").
      #
      # @example
      #   # bad
      #   "His name is #$name"
      #   /check #$pattern/
      #   "Let's go to the #@store"
      #
      #   # good
      #   "His name is #{$name}"
      #   /check #{$pattern}/
      #   "Let's go to the #{@store}"
      class VariableInterpolation < Base
        include Interpolation
        extend AutoCorrector

        MSG = 'Replace interpolated variable `%<variable>s` with expression `#{%<variable>s}`.'

        def on_node_with_interpolations(node)
          var_nodes(node.children).each do |var_node|
            add_offense(var_node) do |corrector|
              corrector.replace(var_node, "{#{var_node.source}}")
            end
          end
        end

        private

        def message(range)
          format(MSG, variable: range.source)
        end

        def var_nodes(nodes)
          nodes.select { |n| n.variable? || n.reference? }
        end
      end
    end
  end
end
