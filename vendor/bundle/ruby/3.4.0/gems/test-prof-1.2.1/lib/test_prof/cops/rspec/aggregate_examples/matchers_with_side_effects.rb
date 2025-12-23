# frozen_string_literal: true

require "test_prof/cops/rspec/language"

module RuboCop
  module Cop
    module RSpec
      class AggregateExamples < ::RuboCop::Cop::Cop
        # When aggregated, the expectations will fail when not supposed to or
        # have a risk of not failing when expected to. One example is
        # `validate_presence_of :comment` as it leaves an empty comment after
        # itself on the subject making it invalid and the subsequent expectation
        # to fail.
        # Examples with those matchers are not supposed to be aggregated.
        #
        # @example MatchersWithSideEffects
        #
        #   # .rubocop.yml
        #   # RSpec/AggregateExamples:
        #   #   MatchersWithSideEffects:
        #   #   - allow_value
        #   #   - allow_values
        #   #   - validate_presence_of
        #
        #   # bad, but isn't automatically correctable
        #   describe do
        #     it { is_expected.to validate_presence_of(:comment) }
        #     it { is_expected.to be_valid }
        #   end
        #
        # @internal
        #   Support for taking special care of the matchers that have side
        #   effects, i.e. leave the subject in a modified state.
        module MatchersWithSideEffects
          extend RuboCop::NodePattern::Macros
          include RuboCop::Cop::RSpec::Language

          MSG_FOR_EXPECTATIONS_WITH_SIDE_EFFECTS =
            "Aggregate with the example at line %d. IMPORTANT! Pay attention " \
            "to the expectation order, some of the matchers have side effects."

          private

          def message_for(example, first_example)
            return super unless example_with_side_effects?(example)

            format(MSG_FOR_EXPECTATIONS_WITH_SIDE_EFFECTS, first_example.loc.line)
          end

          def matcher_with_side_effects_names
            cop_config.fetch("MatchersWithSideEffects", [])
              .map(&:to_sym)
          end

          def matcher_with_side_effects_name?(matcher_name)
            matcher_with_side_effects_names.include?(matcher_name)
          end

          # In addition to base definition, matches examples with:
          # - no matchers known to have side-effects
          def_node_matcher :example_for_autocorrect?, <<-PATTERN
            [ #super !#example_with_side_effects? ]
          PATTERN

          # Matches the example with matcher with side effects
          def_node_matcher :example_with_side_effects?, <<-PATTERN
            (block #{Examples::EXAMPLES.send_pattern} _ #expectation_with_side_effects?)
          PATTERN

          # Matches the expectation with matcher with side effects
          def_node_matcher :expectation_with_side_effects?, <<-PATTERN
            (send #expectation? #{Runners::ALL.node_pattern_union} #matcher_with_side_effects?)
          PATTERN

          # Matches the matcher with side effects
          def_node_search :matcher_with_side_effects?, <<-PATTERN
            (send nil? #matcher_with_side_effects_name? ...)
          PATTERN
        end
      end
    end
  end
end
