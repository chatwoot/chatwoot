# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for uses of `String#split` with empty string or regexp literal argument.
      #
      # @safety
      #   This cop is unsafe because it cannot be guaranteed that the receiver
      #   is actually a string. If another class has a `split` method with
      #   different behavior, it would be registered as a false positive.
      #
      # @example
      #   # bad
      #   string.split(//)
      #   string.split('')
      #
      #   # good
      #   string.chars
      #
      class StringChars < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `chars` instead of `%<current>s`.'
        RESTRICT_ON_SEND = %i[split].freeze
        BAD_ARGUMENTS = %w[// '' ""].freeze

        def on_send(node)
          return unless node.arguments.one? && BAD_ARGUMENTS.include?(node.first_argument.source)

          range = range_between(node.loc.selector.begin_pos, node.source_range.end_pos)

          add_offense(range, message: format(MSG, current: range.source)) do |corrector|
            corrector.replace(range, 'chars')
          end
        end
        alias on_csend on_send
      end
    end
  end
end
