# frozen_string_literal: true

require "test_prof/cops/rspec/aggregate_examples/line_range_helpers"
require "test_prof/cops/rspec/aggregate_examples/metadata_helpers"
require "test_prof/cops/rspec/aggregate_examples/node_matchers"

require "test_prof/cops/rspec/aggregate_examples/its"
require "test_prof/cops/rspec/aggregate_examples/matchers_with_side_effects"

module RuboCop
  module Cop
    module RSpec
      # Checks if example groups contain two or more aggregatable examples.
      #
      # @see https://github.com/rubocop-hq/rspec-style-guide#expectation-per-example
      #
      # This cop is primarily for reducing the cost of repeated expensive
      # context initialization.
      #
      # @example
      #
      #   # bad
      #   describe do
      #     specify do
      #       expect(number).to be_positive
      #       expect(number).to be_odd
      #     end
      #
      #     it { is_expected.to be_prime }
      #   end
      #
      #   # good
      #   describe do
      #     specify do
      #       expect(number).to be_positive
      #       expect(number).to be_odd
      #       is_expected.to be_prime
      #     end
      #   end
      #
      #   # fair - subject has side effects
      #   describe do
      #     specify do
      #       expect(multiply_by(2)).to be_multiple_of(2)
      #     end
      #
      #     specify do
      #       expect(multiply_by(3)).to be_multiple_of(3)
      #     end
      #   end
      #
      # Block expectation syntax is deliberately not supported due to:
      #
      # 1. `subject { -> { ... } }` syntax being hard to detect, e.g. the
      #    following looks like an example with non-block syntax, but it might
      #    be, depending on how the subject is defined:
      #
      #        it { is_expected.to do_something }
      #
      #    If the subject is defined in a `shared_context`, it's impossible to
      #    detect that at all.
      #
      # 2. Aggregation should use composition with an `.and`. Also, aggregation
      #    of the `not_to` expectations is barely possible when a matcher
      #    doesn't provide a negated variant.
      #
      # 3. Aggregation of block syntax with non-block syntax should be in a
      #    specific order.
      #
      # RSpec [comes with an `aggregate_failures` helper](https://relishapp.com/rspec/rspec-expectations/docs/aggregating-failures)
      # not to fail the example on first unmet expectation that might come
      # handy with aggregated examples.
      # It can be [used in metadata form](https://relishapp.com/rspec/rspec-core/docs/expectation-framework-integration/aggregating-failures#use-%60:aggregate-failures%60-metadata),
      # or [enabled globally](https://relishapp.com/rspec/rspec-core/docs/expectation-framework-integration/aggregating-failures#enable-failure-aggregation-globally-using-%60define-derived-metadata%60).
      #
      # @example Globally enable `aggregate_failures`
      #
      #   # spec/spec_helper.rb
      #   config.define_derived_metadata do |metadata|
      #     unless metadata.key?(:aggregate_failures)
      #       metadata[:aggregate_failures] = true
      #     end
      #   end
      #
      # To match the style being used in the spec suite, AggregateExamples
      # can be configured to add `:aggregate_failures` metadata to the
      # example or not. The option not to add metadata can be also used
      # when it's not desired to make expectations after previously failed
      # ones, commonly known as fail-fast.
      #
      # The terms "aggregate examples" and "aggregate failures" not to be
      # confused. The former stands for putting several expectations to
      # a single example. The latter means to run all the expectations in
      # the example instead of aborting on the first one.
      #
      # @example AddAggregateFailuresMetadata: true (default)
      #
      #   # Metadata set using a symbol
      #   specify(:aggregate_failures) do
      #     expect(number).to be_positive
      #     expect(number).to be_odd
      #   end
      #
      # @example AddAggregateFailuresMetadata: false
      #
      #   specify do
      #     expect(number).to be_positive
      #     expect(number).to be_odd
      #   end
      #
      class AggregateExamples < ::RuboCop::Cop::Cop
        include LineRangeHelpers
        include MetadataHelpers
        include NodeMatchers

        # Methods from the following modules override and extend methods of this
        # class, extracting specific behavior.
        prepend Its
        prepend MatchersWithSideEffects

        MSG = "Aggregate with the example at line %d."

        def on_block(node)
          example_group_with_several_examples(node) do |all_examples|
            example_clusters(all_examples).each do |_, examples|
              examples[1..-1].each do |example|
                add_offense(example,
                  location: :expression,
                  message: message_for(example, examples[0]))
              end
            end
          end
        end

        def autocorrect(example_node)
          clusters = example_clusters_for_autocorrect(example_node)
          return if clusters.empty?

          lambda do |corrector|
            clusters.each do |metadata, examples|
              range = range_for_replace(examples)
              replacement = aggregated_example(examples, metadata)
              corrector.replace(range, replacement)
              examples[1..-1].map { |example| drop_example(corrector, example) }
            end
          end
        end

        private

        # Clusters of examples in the same example group, on the same nesting
        # level that can be aggregated.
        def example_clusters(all_examples)
          all_examples
            .select { |example| example_with_expectations_only?(example) }
            .group_by { |example| metadata_without_aggregate_failures(example) }
            .select { |_, examples| examples.count > 1 }
        end

        # Clusters of examples that can be aggregated without losing any
        # information (e.g. metadata or docstrings)
        def example_clusters_for_autocorrect(example_node)
          examples_in_group = example_node.parent.each_child_node(:block)
            .select { |example| example_for_autocorrect?(example) }
          example_clusters(examples_in_group)
        end

        def message_for(_example, first_example)
          format(MSG, first_example.loc.line)
        end

        def drop_example(corrector, example)
          aggregated_range = range_by_whole_lines(example.source_range,
            include_final_newline: true)
          corrector.remove(aggregated_range)
        end

        def aggregated_example(examples, metadata)
          base_indent = " " * examples.first.source_range.column
          metadata = metadata_for_aggregated_example(metadata)
          [
            "#{base_indent}specify#{metadata} do",
            *examples.map { |example| transform_body(example, base_indent) },
            "#{base_indent}end\n"
          ].join("\n")
        end

        # Extracts and transforms the body, keeping proper indentation.
        def transform_body(node, base_indent)
          "#{base_indent}  #{new_body(node)}"
        end

        def new_body(node)
          node.body.source
        end
      end
    end
  end
end
