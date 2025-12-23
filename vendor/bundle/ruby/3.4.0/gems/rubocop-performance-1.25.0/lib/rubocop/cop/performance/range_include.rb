# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Identifies uses of `Range#include?` and `Range#member?`, which iterates over each
      # item in a `Range` to see if a specified item is there. In contrast,
      # `Range#cover?` simply compares the target item with the beginning and
      # end points of the `Range`. In a great majority of cases, this is what
      # is wanted.
      #
      # @safety
      #   This cop is unsafe because `Range#include?` (or `Range#member?`) and `Range#cover?`
      #   are not equivalent behavior.
      #   Example of a case where `Range#cover?` may not provide the desired result:
      #
      #   [source,ruby]
      #   ----
      #   ('a'..'z').cover?('yellow') # => true
      #   ----
      #
      # @example
      #   # bad
      #   ('a'..'z').include?('b') # => true
      #   ('a'..'z').member?('b')  # => true
      #
      #   # good
      #   ('a'..'z').cover?('b') # => true
      class RangeInclude < Base
        extend AutoCorrector

        MSG = 'Use `Range#cover?` instead of `Range#%<bad_method>s`.'
        RESTRICT_ON_SEND = %i[include? member?].freeze

        # TODO: If we traced out assignments of variables to their uses, we
        # might pick up on a few more instances of this issue
        # Right now, we only detect direct calls on a Range literal
        # (We don't even catch it if the Range is in double parens)

        def_node_matcher :range_include, <<~PATTERN
          (call {range (begin range)} ${:include? :member?} ...)
        PATTERN

        def on_send(node)
          range_include(node) do |bad_method|
            message = format(MSG, bad_method: bad_method)

            add_offense(node.loc.selector, message: message) do |corrector|
              corrector.replace(node.loc.selector, 'cover?')
            end
          end
        end
        alias on_csend on_send
      end
    end
  end
end
