# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for duplicate literal, constant, or variable elements in `Set` and `SortedSet`.
      #
      # @example
      #
      #   # bad
      #   Set[:foo, :bar, :foo]
      #
      #   # good
      #   Set[:foo, :bar]
      #
      #   # bad
      #   Set.new([:foo, :bar, :foo])
      #
      #   # good
      #   Set.new([:foo, :bar])
      #
      #   # bad
      #   [:foo, :bar, :foo].to_set
      #
      #   # good
      #   [:foo, :bar].to_set
      #
      #   # bad
      #   SortedSet[:foo, :bar, :foo]
      #
      #   # good
      #   SortedSet[:foo, :bar]
      #
      #   # bad
      #   SortedSet.new([:foo, :bar, :foo])
      #
      #   # good
      #   SortedSet.new([:foo, :bar])
      class DuplicateSetElement < Base
        extend AutoCorrector

        MSG = 'Remove the duplicate element in %<class_name>s.'
        RESTRICT_ON_SEND = %i[\[\] new to_set].freeze

        # @!method set_init_elements(node)
        def_node_matcher :set_init_elements, <<~PATTERN
          {
            (send (const {nil? cbase} {:Set :SortedSet}) :[] $...)
            (send (const {nil? cbase} {:Set :SortedSet}) :new (array $...))
            (call (array $...) :to_set)
          }
        PATTERN

        def on_send(node)
          return unless (set_elements = set_init_elements(node))

          seen_elements = Set[]

          set_elements.each_with_index do |set_element, index|
            # NOTE: Skip due to the possibility of corner cases where Set elements
            # may have changing return values if they are not literals, constants, or variables.
            next if !set_element.literal? && !set_element.const_type? && !set_element.variable?

            if seen_elements.include?(set_element)
              register_offense(set_element, set_elements[index - 1], node)
            else
              seen_elements << set_element
            end
          end
        end
        alias on_csend on_send

        private

        def register_offense(current_element, prev_element, node)
          class_name = node.receiver.const_type? ? node.receiver.const_name : 'Set'

          add_offense(current_element, message: format(MSG, class_name: class_name)) do |corrector|
            range = prev_element.source_range.end.join(current_element.source_range.end)

            corrector.remove(range)
          end
        end
      end
    end
  end
end
