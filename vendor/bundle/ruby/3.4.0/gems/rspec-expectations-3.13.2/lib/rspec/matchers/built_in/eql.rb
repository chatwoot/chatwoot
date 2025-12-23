module RSpec
  module Matchers
    module BuiltIn
      # @api private
      # Provides the implementation for `eql`.
      # Not intended to be instantiated directly.
      class Eql < BaseMatcher
        # @api private
        # @return [String]
        def failure_message
          if string_encoding_differs?
            "\nexpected: #{format_encoding(expected)} #{expected_formatted}\n     got: #{format_encoding(actual)} #{actual_formatted}\n\n(compared using eql?)\n"
          else
            "\nexpected: #{expected_formatted}\n     got: #{actual_formatted}\n\n(compared using eql?)\n"
          end
        end

        # @api private
        # @return [String]
        def failure_message_when_negated
          "\nexpected: value != #{expected_formatted}\n     got: #{actual_formatted}\n\n(compared using eql?)\n"
        end

        # @api private
        # @return [Boolean]
        def diffable?
          true
        end

      private

        def match(expected, actual)
          actual.eql? expected
        end
      end
    end
  end
end
