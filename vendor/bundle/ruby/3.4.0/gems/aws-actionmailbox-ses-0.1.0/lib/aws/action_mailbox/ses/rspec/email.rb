# frozen_string_literal: true

module Aws
  module ActionMailbox
    module SES
      module RSpec
        # @api private
        class Email
          def initialize(authentic: true, topic: 'topic:arn:default', mail: default_mail, message_params: {})
            @authentic = authentic
            @topic = topic
            @mail = mail
            @message_params = message_params
          end

          def headers
            { 'content-type' => 'application/json' }
          end

          def url
            '/rails/action_mailbox/ses/inbound_emails'
          end

          def params
            {
              'Type' => 'Notification',
              'TopicArn' => @topic,
              'Message' => message_json
            }
          end

          def message_json
            {
              'notificationType' => 'Received',
              'content' => @mail.encoded
            }.merge(@message_params).to_json
          end

          def authentic?
            @authentic
          end

          def default_mail
            Mail.new
          end
        end
      end
    end
  end
end
