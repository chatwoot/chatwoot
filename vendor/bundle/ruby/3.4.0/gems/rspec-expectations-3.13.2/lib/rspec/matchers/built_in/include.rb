require 'rspec/matchers/built_in/count_expectation'

module RSpec
  module Matchers
    module BuiltIn
      # @api private
      # Provides the implementation for `include`.
      # Not intended to be instantiated directly.
      class Include < BaseMatcher # rubocop:disable Metrics/ClassLength
        include CountExpectation
        # @private
        attr_reader :expecteds

        # @api private
        def initialize(*expecteds)
          raise(ArgumentError, 'include() is not supported, please supply an argument') if expecteds.empty?
          @expecteds = expecteds
        end

        # @api private
        # @return [Boolean]
        def matches?(actual)
          check_actual?(actual) &&
            if check_expected_count?
              expected_count_matches?(count_inclusions)
            else
              perform_match { |v| v }
            end
        end

        # @api private
        # @return [Boolean]
        def does_not_match?(actual)
          check_actual?(actual) &&
            if check_expected_count?
              !expected_count_matches?(count_inclusions)
            else
              perform_match { |v| !v }
            end
        end

        # @api private
        # @return [String]
        def description
          improve_hash_formatting("include#{readable_list_of(expecteds)}#{count_expectation_description}")
        end

        # @api private
        # @return [String]
        def failure_message
          format_failure_message("to") { super }
        end

        # @api private
        # @return [String]
        def failure_message_when_negated
          format_failure_message("not to") { super }
        end

        # @api private
        # @return [Boolean]
        def diffable?
          !diff_would_wrongly_highlight_matched_item?
        end

        # @api private
        # @return [Array, Hash]
        def expected
          if expecteds.one? && Hash === expecteds.first
            expecteds.first
          else
            expecteds
          end
        end

      private

        def check_actual?(actual)
          actual = actual.to_hash if convert_to_hash?(actual)
          @actual = actual
          @actual.respond_to?(:include?)
        end

        def check_expected_count?
          case
          when !has_expected_count?
            return false
          when expecteds.size != 1
            raise NotImplementedError, 'Count constraint supported only when testing for a single value being included'
          when actual.is_a?(Hash)
            raise NotImplementedError, 'Count constraint on hash keys not implemented'
          end
          true
        end

        def format_failure_message(preposition)
          msg = if actual.respond_to?(:include?)
                  "expected #{description_of @actual} #{preposition}" \
                  " include#{readable_list_of @divergent_items}" \
                  "#{count_failure_reason('it is included') if has_expected_count?}"
                else
                  "#{yield}, but it does not respond to `include?`"
                end
          improve_hash_formatting(msg)
        end

        def readable_list_of(items)
          described_items = surface_descriptions_in(items)
          if described_items.all? { |item| item.is_a?(Hash) }
            " #{described_items.inject(:merge).inspect}"
          else
            EnglishPhrasing.list(described_items)
          end
        end

        def perform_match(&block)
          @divergent_items = excluded_from_actual(&block)
          @divergent_items.empty?
        end

        def excluded_from_actual
          return [] unless @actual.respond_to?(:include?)

          expecteds.inject([]) do |memo, expected_item|
            if comparing_hash_to_a_subset?(expected_item)
              expected_item.each do |(key, value)|
                memo << { key => value } unless yield actual_hash_includes?(key, value)
              end
            elsif comparing_hash_keys?(expected_item)
              memo << expected_item unless yield actual_hash_has_key?(expected_item)
            else
              memo << expected_item unless yield actual_collection_includes?(expected_item)
            end
            memo
          end
        end

        def comparing_hash_to_a_subset?(expected_item)
          actual.is_a?(Hash) && expected_item.is_a?(Hash)
        end

        def actual_hash_includes?(expected_key, expected_value)
          actual_value =
            actual.fetch(expected_key) do
              actual.find(Proc.new { return false }) { |actual_key, _| values_match?(expected_key, actual_key) }[1]
            end
          values_match?(expected_value, actual_value)
        end

        def comparing_hash_keys?(expected_item)
          actual.is_a?(Hash) && !expected_item.is_a?(Hash)
        end

        def actual_hash_has_key?(expected_key)
          # We check `key?` first for perf:
          # `key?` is O(1), but `any?` is O(N).

          has_exact_key =
            begin
              actual.key?(expected_key)
            rescue
              false
            end

          has_exact_key || actual.keys.any? { |key| values_match?(expected_key, key) }
        end

        def actual_collection_includes?(expected_item)
          return true if actual.include?(expected_item)

          # String lacks an `any?` method...
          return false unless actual.respond_to?(:any?)

          actual.any? { |value| values_match?(expected_item, value) }
        end

        if RUBY_VERSION < '1.9'
          # :nocov:
          def count_enumerable(expected_item)
            actual.select { |value| values_match?(expected_item, value) }.size
          end
          # :nocov:
        else
          def count_enumerable(expected_item)
            actual.count { |value| values_match?(expected_item, value) }
          end
        end

        def count_inclusions
          @divergent_items = expected
          case actual
          when String
            actual.scan(expected.first).length
          when Enumerable
            count_enumerable(Hash === expected ? expected : expected.first)
          else
            raise NotImplementedError, 'Count constraints are implemented for Enumerable and String values only'
          end
        end

        def diff_would_wrongly_highlight_matched_item?
          return false unless actual.is_a?(String) && expected.is_a?(Array)

          lines = actual.split("\n")
          expected.any? do |str|
            actual.include?(str) && lines.none? { |line| line == str }
          end
        end

        def convert_to_hash?(obj)
          !obj.respond_to?(:include?) && obj.respond_to?(:to_hash)
        end
      end
    end
  end
end
