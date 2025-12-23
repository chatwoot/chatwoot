# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks for redundant `travel_back` calls.
      # Since Rails 5.2, `travel_back` is automatically called at the end of the test.
      #
      # @example
      #
      #   # bad
      #   def teardown
      #     do_something
      #     travel_back
      #   end
      #
      #   # good
      #   def teardown
      #     do_something
      #   end
      #
      #   # bad
      #   after do
      #     do_something
      #     travel_back
      #   end
      #
      #   # good
      #   after do
      #     do_something
      #   end
      #
      class RedundantTravelBack < Base
        include RangeHelp
        extend AutoCorrector
        extend TargetRailsVersion

        minimum_target_rails_version 5.2

        MSG = 'Redundant `travel_back` detected.'
        RESTRICT_ON_SEND = %i[travel_back].freeze

        def on_send(node)
          return unless node.each_ancestor(:def, :block).any? do |ancestor|
            method_name = ancestor.def_type? ? :teardown : :after

            ancestor.method?(method_name)
          end

          add_offense(node) do |corrector|
            corrector.remove(range_by_whole_lines(node.source_range, include_final_newline: true))
          end
        end
      end
    end
  end
end
