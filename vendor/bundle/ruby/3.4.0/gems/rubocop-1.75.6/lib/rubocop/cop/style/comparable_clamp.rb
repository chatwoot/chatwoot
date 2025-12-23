# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Enforces the use of `Comparable#clamp` instead of comparison by minimum and maximum.
      #
      # This cop supports autocorrection for `if/elsif/else` bad style only.
      # Because `ArgumentError` occurs if the minimum and maximum of `clamp` arguments are reversed.
      # When these are variables, it is not possible to determine which is the minimum and maximum:
      #
      # [source,ruby]
      # ----
      # [1, [2, 3].max].min # => 1
      # 1.clamp(3, 1)       # => min argument must be smaller than max argument (ArgumentError)
      # ----
      #
      # @example
      #
      #   # bad
      #   [[x, low].max, high].min
      #
      #   # bad
      #   if x < low
      #     low
      #   elsif high < x
      #     high
      #   else
      #     x
      #   end
      #
      #   # good
      #   x.clamp(low, high)
      #
      class ComparableClamp < Base
        include Alignment
        extend AutoCorrector
        extend TargetRubyVersion

        minimum_target_ruby_version 2.4

        MSG = 'Use `%<prefer>s` instead of `if/elsif/else`.'
        MSG_MIN_MAX = 'Use `Comparable#clamp` instead.'
        RESTRICT_ON_SEND = %i[min max].freeze

        # @!method if_elsif_else_condition?(node)
        def_node_matcher :if_elsif_else_condition?, <<~PATTERN
          {
            (if (send _x :< _min) _min (if (send _max :< _x) _max _x))
            (if (send _min :> _x) _min (if (send _max :< _x) _max _x))
            (if (send _x :< _min) _min (if (send _x :> _max) _max _x))
            (if (send _min :> _x) _min (if (send _x :> _max) _max _x))
            (if (send _max :< _x) _max (if (send _x :< _min) _min _x))
            (if (send _x :> _max) _max (if (send _x :< _min) _min _x))
            (if (send _max :< _x) _max (if (send _min :> _x) _min _x))
            (if (send _x :> _max) _max (if (send _min :> _x) _min _x))
          }
        PATTERN

        # @!method array_min_max?(node)
        def_node_matcher :array_min_max?, <<~PATTERN
          {
            (send
              (array
                (send (array _ _) :max) _) :min)
            (send
              (array
                _ (send (array _ _) :max)) :min)
            (send
              (array
                (send (array _ _) :min) _) :max)
            (send
              (array
                _ (send (array _ _) :min)) :max)
          }
        PATTERN

        def on_if(node)
          return unless if_elsif_else_condition?(node)

          if_body, elsif_body, else_body = *node.branches

          else_body_source = else_body.source

          if min_condition?(node.condition, else_body_source)
            min = if_body.source
            max = elsif_body.source
          else
            min = elsif_body.source
            max = if_body.source
          end

          prefer = "#{else_body_source}.clamp(#{min}, #{max})"

          add_offense(node, message: format(MSG, prefer: prefer)) do |corrector|
            autocorrect(corrector, node, prefer)
          end
        end

        def on_send(node)
          return unless array_min_max?(node)

          add_offense(node, message: MSG_MIN_MAX)
        end

        private

        def autocorrect(corrector, node, prefer)
          if node.elsif?
            corrector.insert_before(node, "else\n")
            corrector.replace(node, "#{indentation(node)}#{prefer}")
          else
            corrector.replace(node, prefer)
          end
        end

        def min_condition?(if_condition, else_body)
          lhs, op, rhs = *if_condition

          (lhs.source == else_body && op == :<) || (rhs.source == else_body && op == :>)
        end
      end
    end
  end
end
