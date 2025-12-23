# frozen_string_literal: true

module RSpec
  module Rails
    module Matchers
      # @api private
      #
      # Matcher class for `send_email`. Should not be instantiated directly.
      #
      # @see RSpec::Rails::Matchers#send_email
      class SendEmail < RSpec::Rails::Matchers::BaseMatcher
        # @api private
        # Define the email attributes that should be included in the inspection output.
        INSPECT_EMAIL_ATTRIBUTES = %i[subject from to cc bcc].freeze

        def initialize(criteria)
          @criteria = criteria
        end

        # @api private
        def supports_value_expectations?
          false
        end

        # @api private
        def supports_block_expectations?
          true
        end

        def matches?(block)
          define_matched_emails(block)

          @matched_emails.one?
        end

        # @api private
        # @return [String]
        def failure_message
          result =
            if multiple_match?
              "More than 1 matching emails were sent."
            else
              "No matching emails were sent."
            end
          "#{result}#{sent_emails_message}"
        end

        # @api private
        # @return [String]
        def failure_message_when_negated
          "Expected not to send an email but it was sent."
        end

        private

        def diffable?
          true
        end

        def deliveries
          ActionMailer::Base.deliveries
        end

        def define_matched_emails(block)
          before = deliveries.dup

          block.call

          after = deliveries

          @diff = after - before
          @matched_emails = @diff.select(&method(:matched_email?))
        end

        def matched_email?(email)
          @criteria.all? do |attr, value|
            expected =
              case attr
              when :to, :from, :cc, :bcc then Array(value)
              else
                value
              end

            values_match?(expected, email.public_send(attr))
          end
        end

        def multiple_match?
          @matched_emails.many?
        end

        def sent_emails_message
          if @diff.empty?
            "\n\nThere were no any emails sent inside the expectation block."
          else
            sent_emails =
              @diff.map do |email|
                inspected = INSPECT_EMAIL_ATTRIBUTES.map { |attr| "#{attr}: #{email.public_send(attr)}" }.join(", ")
                "- #{inspected}"
              end.join("\n")
            "\n\nThe following emails were sent:\n#{sent_emails}"
          end
        end
      end

      # @api public
      # Check email sending with specific parameters.
      #
      # @example Positive expectation
      #   expect { action }.to send_email
      #
      # @example Negative expectations
      #   expect { action }.not_to send_email
      #
      # @example More precise expectation with attributes to match
      #   expect { action }.to send_email(to: 'test@example.com', subject: 'Confirm email')
      def send_email(criteria = {})
        SendEmail.new(criteria)
      end
    end
  end
end
