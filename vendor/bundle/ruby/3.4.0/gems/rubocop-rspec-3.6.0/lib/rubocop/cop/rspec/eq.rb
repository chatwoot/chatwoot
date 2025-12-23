# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Use `eq` instead of `be ==` to compare objects.
      #
      # @example
      #   # bad
      #   expect(foo).to be == 42
      #
      #   # good
      #   expect(foo).to eq 42
      #
      class Eq < Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'Use `eq` instead of `be ==` to compare objects.'
        RESTRICT_ON_SEND = Runners.all

        # @!method be_equals(node)
        def_node_matcher :be_equals, <<~PATTERN
          (send _ #Runners.all $(send (send nil? :be) :== _))
        PATTERN

        def on_send(node)
          be_equals(node) do |matcher|
            range = offense_range(matcher)
            add_offense(range) do |corrector|
              corrector.replace(range, 'eq')
            end
          end
        end

        private

        def offense_range(matcher)
          range_between(
            matcher.source_range.begin_pos,
            matcher.loc.selector.end_pos
          )
        end
      end
    end
  end
end
