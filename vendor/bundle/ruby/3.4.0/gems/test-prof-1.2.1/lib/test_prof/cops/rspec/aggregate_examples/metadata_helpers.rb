# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      class AggregateExamples < ::RuboCop::Cop::Cop
        # @internal
        #   Support methods for example metadata.
        #   Examples with similar metadata are grouped.
        #
        #   Depending on the configuration, `aggregate_failures` metadata
        #   is added to aggregated examples.
        module MetadataHelpers
          private

          def metadata_for_aggregated_example(metadata)
            metadata_to_add = metadata.compact.map(&:source)
            if add_aggregate_failures_metadata?
              metadata_to_add.unshift(":aggregate_failures")
            end
            if metadata_to_add.any?
              "(#{metadata_to_add.join(", ")})"
            else
              ""
            end
          end

          # Used to group examples for aggregation. `aggregate_failures`
          # and `aggregate_failures: true` metadata are not taken in
          # consideration, as it is dynamically set basing on cofiguration.
          # If `aggregate_failures: false` is set on the example, it's
          # preserved and is treated as regular metadata.
          def metadata_without_aggregate_failures(example)
            metadata = example_metadata(example) || []

            symbols = metadata_symbols_without_aggregate_failures(metadata)
            pairs = metadata_pairs_without_aggegate_failures(metadata)

            [*symbols, pairs].flatten.compact
          end

          def example_metadata(example)
            example.send_node.arguments
          end

          def metadata_symbols_without_aggregate_failures(metadata)
            metadata
              .select(&:sym_type?)
              .reject { |item| item.value == :aggregate_failures }
          end

          def metadata_pairs_without_aggegate_failures(metadata)
            map = metadata.find(&:hash_type?)
            pairs = map&.pairs || []
            pairs.reject do |pair|
              pair.key.value == :aggregate_failures && pair.value.true_type?
            end
          end

          def add_aggregate_failures_metadata?
            cop_config.fetch("AddAggregateFailuresMetadata", false)
          end
        end
      end
    end
  end
end
