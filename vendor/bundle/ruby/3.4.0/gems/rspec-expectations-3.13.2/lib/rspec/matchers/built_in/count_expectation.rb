module RSpec
  module Matchers
    module BuiltIn
      # @api private
      # Abstract class to implement `once`, `at_least` and other
      # count constraints.
      module CountExpectation
        # @api public
        # Specifies that the method is expected to match once.
        def once
          exactly(1)
        end

        # @api public
        # Specifies that the method is expected to match twice.
        def twice
          exactly(2)
        end

        # @api public
        # Specifies that the method is expected to match thrice.
        def thrice
          exactly(3)
        end

        # @api public
        # Specifies that the method is expected to match the given number of times.
        def exactly(number)
          set_expected_count(:==, number)
          self
        end

        # @api public
        # Specifies the maximum number of times the method is expected to match
        def at_most(number)
          set_expected_count(:<=, number)
          self
        end

        # @api public
        # Specifies the minimum number of times the method is expected to match
        def at_least(number)
          set_expected_count(:>=, number)
          self
        end

        # @api public
        # No-op. Provides syntactic sugar.
        def times
          self
        end

      protected
        # @api private
        attr_reader :count_expectation_type, :expected_count

      private

        if RUBY_VERSION.to_f > 1.8
          def cover?(count, number)
            count.cover?(number)
          end
        else
          # :nocov:
          def cover?(count, number)
            number >= count.first && number <= count.last
          end
          # :nocov:
        end

        def expected_count_matches?(actual_count)
          @actual_count = actual_count
          return @actual_count > 0 unless count_expectation_type
          return cover?(expected_count, actual_count) if count_expectation_type == :<=>

          @actual_count.__send__(count_expectation_type, expected_count)
        end

        def has_expected_count?
          !!count_expectation_type
        end

        def set_expected_count(relativity, n)
          raise_unsupported_count_expectation if unsupported_count_expectation?(relativity)

          count = count_constraint_to_number(n)

          if count_expectation_type == :<= && relativity == :>=
            raise_impossible_count_expectation(count) if count > expected_count
            @count_expectation_type = :<=>
            @expected_count = count..expected_count
          elsif count_expectation_type == :>= && relativity == :<=
            raise_impossible_count_expectation(count) if count < expected_count
            @count_expectation_type = :<=>
            @expected_count = expected_count..count
          else
            @count_expectation_type = relativity
            @expected_count = count
          end
        end

        def raise_impossible_count_expectation(count)
          text =
            case count_expectation_type
            when :<= then "at_least(#{count}).at_most(#{expected_count})"
            when :>= then "at_least(#{expected_count}).at_most(#{count})"
            end
          raise ArgumentError, "The constraint #{text} is not possible"
        end

        def raise_unsupported_count_expectation
          text =
            case count_expectation_type
            when :<= then "at_least"
            when :>= then "at_most"
            when :<=> then "at_least/at_most combination"
            else "count"
            end
          raise ArgumentError, "Multiple #{text} constraints are not supported"
        end

        def count_constraint_to_number(n)
          case n
          when Numeric then n
          when :once then 1
          when :twice then 2
          when :thrice then 3
          else
            raise ArgumentError, "Expected a number, :once, :twice or :thrice," \
              " but got #{n}"
          end
        end

        def unsupported_count_expectation?(relativity)
          return true if count_expectation_type == :==
          return true if count_expectation_type == :<=>
          (count_expectation_type == :<= && relativity == :<=) ||
            (count_expectation_type == :>= && relativity == :>=)
        end

        def count_expectation_description
          "#{human_readable_expectation_type}#{human_readable_count(expected_count)}"
        end

        def count_failure_reason(action)
          "#{count_expectation_description}" \
          " but #{action}#{human_readable_count(@actual_count)}"
        end

        def human_readable_expectation_type
          case count_expectation_type
          when :<= then ' at most'
          when :>= then ' at least'
          when :<=> then ' between'
          else ''
          end
        end

        def human_readable_count(count)
          case count
          when Range then " #{count.first} and #{count.last} times"
          when nil then ''
          when 1 then ' once'
          when 2 then ' twice'
          else " #{count} times"
          end
        end
      end
    end
  end
end
