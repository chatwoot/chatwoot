# frozen_string_literal: true

require_relative 'rspec/email'
require_relative 'rspec/subscription_confirmation'

module Aws
  module ActionMailbox
    module SES
      # RSpec extension for testing Amazon SES notifications. Include the
      # `Aws::ActionMailbox::SES::RSpec` extension in your tests, like so:
      #
      #     require 'aws/rails/action_mailbox/rspec'
      #     RSpec.configure do |config|
      #       config.include Aws::ActionMailbox::SES::RSpec
      #     end
      #
      module RSpec
        # Stubs the AWS SNS message verifier and delivers a subscription confirmation.
        # @example
        #   it 'delivers a subscription notification' do
        #     action_mailbox_ses_deliver_subscription_confirmation
        #     expect(response).to have_http_status :ok
        #   end
        def action_mailbox_ses_deliver_subscription_confirmation(options = {})
          subscription_confirmation = SubscriptionConfirmation.new(**options)
          stub_aws_sns_message_verifier(subscription_confirmation)
          stub_aws_sns_subscription_request

          post subscription_confirmation.url,
               params: subscription_confirmation.params,
               headers: subscription_confirmation.headers,
               as: :json
        end

        # Stubs the AWS SNS message verifier and delivers an email.
        # @example
        #   it 'delivers an email notification' do
        #     action_mailbox_ses_deliver_email(mail: Mail.new(to: 'user@example.com'))
        #     expect(ActionMailbox::InboundEmail.last.mail.recipients).to eql ['user@example.com']
        #   end
        def action_mailbox_ses_deliver_email(options = {})
          email = Email.new(**options)
          stub_aws_sns_message_verifier(email)

          post email.url,
               params: email.params,
               headers: email.headers,
               as: :json
        end

        private

        def message_verifier(subscription_confirmation)
          instance_double(Aws::SNS::MessageVerifier, authentic?: subscription_confirmation.authentic?)
        end

        def stub_aws_sns_message_verifier(notification)
          allow(Aws::ActionMailbox::SES::SNSMessageVerifier).to receive(:verifier) { message_verifier(notification) }
        end

        def stub_aws_sns_subscription_request
          allow(Net::HTTP).to receive(:get_response).and_call_original
          allow(Net::HTTP)
            .to receive(:get_response)
              .with(URI('http://example.com/subscribe')) { double(code: '200') }
        end
      end
    end
  end
end
