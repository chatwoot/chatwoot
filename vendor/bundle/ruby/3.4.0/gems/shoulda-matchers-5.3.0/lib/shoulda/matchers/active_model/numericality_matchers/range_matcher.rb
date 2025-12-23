require 'active_support/core_ext/module/delegation'

module Shoulda
  module Matchers
    module ActiveModel
      module NumericalityMatchers
        # @private
        class RangeMatcher < ValidationMatcher
          OPERATORS = [:>=, :<=].freeze

          delegate :failure_message, to: :submatchers

          def initialize(numericality_matcher, attribute, range)
            super(attribute)
            unless numericality_matcher.respond_to? :diff_to_compare
              raise ArgumentError, 'numericality_matcher is invalid'
            end

            @numericality_matcher = numericality_matcher
            @range = range
            @attribute = attribute
          end

          def matches?(subject)
            @subject = subject
            submatchers.matches?(subject)
          end

          def simple_description
            description = ''

            if expects_strict?
              description << ' strictly'
            end

            description +
              "disallow :#{attribute} from being a number that is not " +
              range_description
          end

          def range_description
            "from #{Shoulda::Matchers::Util.inspect_range(@range)}"
          end

          def submatchers
            @_submatchers ||= NumericalityMatchers::Submatchers.new(build_submatchers)
          end

          private

          def build_submatchers
            submatcher_combos.map do |value, operator|
              build_comparison_submatcher(value, operator)
            end
          end

          def submatcher_combos
            @range.minmax.zip(OPERATORS)
          end

          def build_comparison_submatcher(value, operator)
            NumericalityMatchers::ComparisonMatcher.new(@numericality_matcher, value, operator).
              for(@attribute).
              with_message(@message).
              on(@context)
          end
        end
      end
    end
  end
end
