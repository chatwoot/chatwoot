# frozen_string_literal: true

require "test_prof/cops/rspec/language"

module RuboCop
  module Cop
    module RSpec
      class AggregateExamples < ::RuboCop::Cop::Cop
        # @internal
        #   Node matchers and searchers.
        module NodeMatchers
          extend RuboCop::NodePattern::Macros
          include RuboCop::Cop::RSpec::Language

          private

          def_node_matcher :example_group_with_several_examples, <<-PATTERN
            (block
              #{ExampleGroups::ALL.send_pattern}
              _
              (begin $...)
            )
          PATTERN

          def example_method?(method_name)
            %i[it specify example scenario].include?(method_name)
          end

          # Matches examples with:
          # - expectation statements exclusively
          # - no title (e.g. `it('jumps over the lazy dog')`)
          # - no HEREDOC
          def_node_matcher :example_for_autocorrect?, <<-PATTERN
            [
              #example_with_expectations_only?
              !#example_has_title?
              !#contains_heredoc?
            ]
          PATTERN

          def_node_matcher :example_with_expectations_only?, <<-PATTERN
            (block #{Examples::EXAMPLES.send_pattern} _
              { #single_expectation? (begin #single_expectation?+) }
            )
          PATTERN

          # Matches the example with a title (e.g. `it('is valid')`)
          def_node_matcher :example_has_title?, <<-PATTERN
            (block
              (send nil? #example_method? str ...)
              ...
            )
          PATTERN

          # Searches for HEREDOC in examples. It can be tricky to aggregate,
          # especially when interleaved with parenthesis or curly braces.
          def contains_heredoc?(node)
            node.each_descendant(:str, :xstr, :dstr).any?(&:heredoc?)
          end

          def_node_matcher :subject_with_no_args?, <<-PATTERN
            (send _ _)
          PATTERN

          def_node_matcher :expectation?, <<-PATTERN
            {
              (send nil? {:is_expected :are_expected})
              (send nil? :expect #subject_with_no_args?)
            }
          PATTERN

          def_node_matcher :single_expectation?, <<-PATTERN
            (send #expectation? #{Runners::ALL.node_pattern_union} _)
          PATTERN
        end
      end
    end
  end
end
