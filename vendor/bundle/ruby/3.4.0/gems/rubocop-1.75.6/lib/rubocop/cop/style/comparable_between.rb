# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for logical comparison which can be replaced with `Comparable#between?`.
      #
      # NOTE: `Comparable#between?` is on average slightly slower than logical comparison,
      # although the difference generally isn't observable. If you require maximum
      # performance, consider using logical comparison.
      #
      # @safety
      #   This cop is unsafe because the receiver may not respond to `between?`.
      #
      # @example
      #
      #   # bad
      #   x >= min && x <= max
      #
      #   # bad
      #   x <= max && x >= min
      #
      #   # good
      #   x.between?(min, max)
      #
      class ComparableBetween < Base
        extend AutoCorrector

        MSG = 'Prefer `%<prefer>s` over logical comparison.'

        # @!method logical_comparison_between_by_min_first?(node)
        def_node_matcher :logical_comparison_between_by_min_first?, <<~PATTERN
          (and
            (send
              {$_value :>= $_min | $_min :<= $_value})
            (send
              {$_value :<= $_max | $_max :>= $_value}))
        PATTERN

        # @!method logical_comparison_between_by_max_first?(node)
        def_node_matcher :logical_comparison_between_by_max_first?, <<~PATTERN
          (and
            (send
              {$_value :<= $_max | $_max :>= $_value})
            (send
              {$_value :>= $_min | $_min :<= $_value}))
        PATTERN

        def on_and(node)
          logical_comparison_between_by_min_first?(node) do |*args|
            min_and_value, max_and_value = args.each_slice(2).to_a

            register_offense(node, min_and_value, max_and_value)
          end

          logical_comparison_between_by_max_first?(node) do |*args|
            max_and_value, min_and_value = args.each_slice(2).to_a

            register_offense(node, min_and_value, max_and_value)
          end
        end

        private

        def register_offense(node, min_and_value, max_and_value)
          value = (min_and_value & max_and_value).first
          min = min_and_value.find { _1 != value } || value
          max = max_and_value.find { _1 != value } || value

          prefer = "#{value.source}.between?(#{min.source}, #{max.source})"
          add_offense(node, message: format(MSG, prefer: prefer)) do |corrector|
            corrector.replace(node, prefer)
          end
        end
      end
    end
  end
end
