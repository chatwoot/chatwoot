# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Enforces the use of `node.single_line?` instead of
      # comparing `first_line` and `last_line` for equality.
      #
      # @example
      #   # bad
      #   node.loc.first_line == node.loc.last_line
      #
      #   # bad
      #   node.loc.last_line == node.loc.first_line
      #
      #   # bad
      #   node.loc.line == node.loc.last_line
      #
      #   # bad
      #   node.loc.last_line == node.loc.line
      #
      #   # bad
      #   node.first_line == node.last_line
      #
      #   # good
      #   node.single_line?
      #
      class SingleLineComparison < Base
        extend AutoCorrector

        MSG = 'Use `%<preferred>s`.'
        RESTRICT_ON_SEND = %i[== !=].freeze

        # @!method single_line_comparison(node)
        def_node_matcher :single_line_comparison, <<~PATTERN
          {
            (send (call $_receiver {:line :first_line}) {:== :!=} (call _receiver :last_line))
            (send (call $_receiver :last_line) {:== :!=} (call _receiver {:line :first_line}))
          }
        PATTERN

        def on_send(node)
          return unless (receiver = single_line_comparison(node))

          bang = node.method?(:!=) ? '!' : ''
          dot = receiver.parent.loc.dot.source
          preferred = "#{bang}#{extract_receiver(receiver)}#{dot}single_line?"

          add_offense(node, message: format(MSG, preferred: preferred)) do |corrector|
            corrector.replace(node, preferred)
          end
        end

        private

        def extract_receiver(node)
          node = node.receiver if node.call_type? && %i[loc source_range].include?(node.method_name)
          node.source
        end
      end
    end
  end
end
