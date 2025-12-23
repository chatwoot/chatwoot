# frozen_string_literal: true

module Aws
  module ActionMailbox
    module SES
      module RSpec
        # @api private
        class SubscriptionConfirmation
          def initialize(authentic: true, topic: 'topic:arn:default')
            @authentic = authentic
            @topic = topic
          end

          def url
            '/rails/action_mailbox/ses/inbound_emails'
          end

          def headers
            { 'content-type' => 'application/json' }
          end

          def params
            {
              'Type' => 'SubscriptionConfirmation',
              'TopicArn' => @topic,
              'SubscribeURL' => 'http://example.com/subscribe'
            }
          end

          def authentic?
            @authentic
          end
        end
      end
    end
  end
end
