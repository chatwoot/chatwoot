module RSpec
  module Matchers
    module BuiltIn
      # @api private
      # Provides the implementation for `be_truthy`.
      # Not intended to be instantiated directly.
      class BeTruthy < BaseMatcher
        # @api private
        # @return [String]
        def failure_message
          "expected: truthy value\n     got: #{actual_formatted}"
        end

        # @api private
        # @return [String]
        def failure_message_when_negated
          "expected: falsey value\n     got: #{actual_formatted}"
        end

      private

        def match(_, actual)
          !!actual
        end
      end

      # @api private
      # Provides the implementation for `be_falsey`.
      # Not intended to be instantiated directly.
      class BeFalsey < BaseMatcher
        # @api private
        # @return [String]
        def failure_message
          "expected: falsey value\n     got: #{actual_formatted}"
        end

        # @api private
        # @return [String]
        def failure_message_when_negated
          "expected: truthy value\n     got: #{actual_formatted}"
        end

      private

        def match(_, actual)
          !actual
        end
      end

      # @api private
      # Provides the implementation for `be_nil`.
      # Not intended to be instantiated directly.
      class BeNil < BaseMatcher
        # @api private
        # @return [String]
        def failure_message
          "expected: nil\n     got: #{actual_formatted}"
        end

        # @api private
        # @return [String]
        def failure_message_when_negated
          "expected: not nil\n     got: nil"
        end

      private

        def match(_, actual)
          actual.nil?
        end
      end

      # @private
      module BeHelpers
      private

        def args_to_s
          @args.empty? ? "" : parenthesize(inspected_args.join(', '))
        end

        def parenthesize(string)
          "(#{string})"
        end

        def inspected_args
          @args.map { |a| RSpec::Support::ObjectFormatter.format(a) }
        end

        def expected_to_sentence
          EnglishPhrasing.split_words(@expected)
        end

        def args_to_sentence
          EnglishPhrasing.list(@args)
        end
      end

      # @api private
      # Provides the implementation for `be`.
      # Not intended to be instantiated directly.
      class Be < BaseMatcher
        include BeHelpers

        def initialize(*args)
          @args = args
        end

        # @api private
        # @return [String]
        def failure_message
          "expected #{actual_formatted} to evaluate to true"
        end

        # @api private
        # @return [String]
        def failure_message_when_negated
          "expected #{actual_formatted} to evaluate to false"
        end

        [:==, :<, :<=, :>=, :>, :===, :=~].each do |operator|
          define_method operator do |operand|
            BeComparedTo.new(operand, operator)
          end
        end

      private

        def match(_, actual)
          !!actual
        end
      end

      # @api private
      # Provides the implementation of `be <operator> value`.
      # Not intended to be instantiated directly.
      class BeComparedTo < BaseMatcher
        include BeHelpers

        def initialize(operand, operator)
          @expected = operand
          @operator = operator
          @args = []
        end

        def matches?(actual)
          perform_match(actual)
        rescue ArgumentError, NoMethodError
          false
        end

        def does_not_match?(actual)
          !perform_match(actual)
        rescue ArgumentError, NoMethodError
          false
        end

        # @api private
        # @return [String]
        def failure_message
          "expected: #{@operator} #{expected_formatted}\n" \
          "     got: #{@operator.to_s.gsub(/./, ' ')} #{actual_formatted}"
        end

        # @api private
        # @return [String]
        def failure_message_when_negated
          message = "`expect(#{actual_formatted}).not_to " \
                    "be #{@operator} #{expected_formatted}`"
          if [:<, :>, :<=, :>=].include?(@operator)
            message + " not only FAILED, it is a bit confusing."
          else
            message
          end
        end

        # @api private
        # @return [String]
        def description
          "be #{@operator} #{expected_to_sentence}#{args_to_sentence}"
        end

      private

        def perform_match(actual)
          @actual = actual
          @actual.__send__ @operator, @expected
        end
      end
    end
  end
end
