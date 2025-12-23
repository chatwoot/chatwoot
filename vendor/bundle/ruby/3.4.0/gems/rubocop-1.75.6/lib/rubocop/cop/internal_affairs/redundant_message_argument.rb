# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Checks for redundant message arguments to `#add_offense`. This method
      # will automatically use `#message` or `MSG` (in that order of priority)
      # if they are defined.
      #
      # @example
      #
      #   # bad
      #   add_offense(node, message: MSG)
      #
      #   # good
      #   add_offense(node)
      #
      class RedundantMessageArgument < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Redundant message argument to `#add_offense`.'
        RESTRICT_ON_SEND = %i[add_offense].freeze

        # @!method node_type_check(node)
        def_node_matcher :node_type_check, <<~PATTERN
          (send nil? :add_offense _node $hash)
        PATTERN

        # @!method redundant_message_argument(node)
        def_node_matcher :redundant_message_argument, <<~PATTERN
          (pair
            (sym :message)
            $(const nil? :MSG))
        PATTERN

        def on_send(node)
          return unless (kwargs = node_type_check(node))

          kwargs.pairs.each do |pair|
            redundant_message_argument(pair) do
              add_offense(pair) do |corrector|
                range = offending_range(pair)

                corrector.remove(range)
              end
            end
          end
        end

        private

        def offending_range(node)
          with_space = range_with_surrounding_space(node.source_range)

          range_with_surrounding_comma(with_space, :left)
        end
      end
    end
  end
end
