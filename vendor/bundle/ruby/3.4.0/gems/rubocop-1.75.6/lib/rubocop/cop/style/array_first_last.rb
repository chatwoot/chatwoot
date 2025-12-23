# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Identifies usages of `arr[0]` and `arr[-1]` and suggests to change
      # them to use `arr.first` and `arr.last` instead.
      #
      # The cop is disabled by default due to safety concerns.
      #
      # @safety
      #   This cop is unsafe because `[0]` or `[-1]` can be called on a Hash,
      #   which returns a value for `0` or `-1` key, but changing these to use
      #   `.first` or `.last` will return first/last tuple instead. Also, String
      #   does not implement `first`/`last` methods.
      #
      # @example
      #   # bad
      #   arr[0]
      #   arr[-1]
      #
      #   # good
      #   arr.first
      #   arr.last
      #   arr[0] = 2
      #   arr[0][-2]
      #
      class ArrayFirstLast < Base
        extend AutoCorrector

        MSG = 'Use `%<preferred>s`.'
        RESTRICT_ON_SEND = %i[[]].freeze

        # rubocop:disable Metrics/AbcSize
        def on_send(node)
          return unless node.arguments.size == 1 && node.first_argument.int_type?

          value = node.first_argument.value
          return unless [0, -1].include?(value)

          node = innermost_braces_node(node)
          return if node.parent && brace_method?(node.parent)

          preferred = (value.zero? ? 'first' : 'last')
          offense_range = find_offense_range(node)

          add_offense(offense_range, message: format(MSG, preferred: preferred)) do |corrector|
            corrector.replace(offense_range, preferred_value(node, preferred))
          end
        end
        # rubocop:enable Metrics/AbcSize
        alias on_csend on_send

        private

        def preferred_value(node, value)
          value = ".#{value}" unless node.loc.dot
          value
        end

        def find_offense_range(node)
          if node.loc.dot
            node.loc.selector.join(node.source_range.end)
          else
            node.loc.selector
          end
        end

        def innermost_braces_node(node)
          node = node.receiver while node.receiver.send_type? && node.receiver.method?(:[])
          node
        end

        def brace_method?(node)
          node.send_type? && (node.method?(:[]) || node.method?(:[]=))
        end
      end
    end
  end
end
