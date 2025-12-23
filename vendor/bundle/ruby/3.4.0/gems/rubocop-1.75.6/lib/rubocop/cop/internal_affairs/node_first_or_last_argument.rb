# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Checks for the use of `node.arguments.first` or `node.arguments.last` and
      # suggests the use of `node.first_argument` or `node.last_argument` instead.
      #
      # @example
      #   # bad
      #   node.arguments.first
      #   node.arguments[0]
      #   node.arguments.last
      #   node.arguments[-1]
      #
      #   # good
      #   node.first_argument
      #   node.last_argument
      #
      class NodeFirstOrLastArgument < Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'Use `#%<correct>s` instead of `#%<incorrect>s`.'
        RESTRICT_ON_SEND = %i[arguments].freeze

        # @!method arguments_first_or_last?(node)
        def_node_matcher :arguments_first_or_last?, <<~PATTERN
          {
            (call (call !nil? :arguments) ${:first :last})
            (call (call !nil? :arguments) :[] (int ${0 -1}))
          }
        PATTERN

        def on_send(node)
          arguments_first_or_last?(node.parent) do |end_or_index|
            range = range_between(node.loc.selector.begin_pos, node.parent.source_range.end_pos)
            correct = case end_or_index
                      when :first, 0 then 'first_argument'
                      when :last, -1 then 'last_argument'
                      else raise "Unknown end_or_index: #{end_or_index}"
                      end
            message = format(MSG, correct: correct, incorrect: range.source)

            add_offense(range, message: message) do |corrector|
              corrector.replace(range, correct)
            end
          end
        end
        alias on_csend on_send
      end
    end
  end
end
