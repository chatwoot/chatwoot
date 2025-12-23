module RSpec
  module Rails
    module Matchers
      module ActionCable
        # @api private
        # Provides the implementation for `have_stream`, `have_stream_for`, and `have_stream_from`.
        # Not intended to be instantiated directly.
        class HaveStream < RSpec::Matchers::BuiltIn::BaseMatcher
          # @api private
          # @return [String]
          def failure_message
            "expected to have #{base_message}"
          end

          # @api private
          # @return [String]
          def failure_message_when_negated
            "expected not to have #{base_message}"
          end

          # @api private
          # @return [Boolean]
          def matches?(subscription)
            raise(ArgumentError, "have_streams is used for negated expectations only") if no_expected?

            match(subscription)
          end

          # @api private
          # @return [Boolean]
          def does_not_match?(subscription)
            !match(subscription)
          end

        private

          def match(subscription)
            case subscription
            when ::ActionCable::Channel::Base
              @actual = subscription.streams
              no_expected? ? actual.any? : actual.any? { |i| expected === i }
            else
              raise ArgumentError, "have_stream, have_stream_from and have_stream_from support expectations on subscription only"
            end
          end

          def base_message
            no_expected? ? "any stream started" : "stream #{expected_formatted} started, but have #{actual_formatted}"
          end

          def no_expected?
            !defined?(@expected)
          end
        end
      end
    end
  end
end
