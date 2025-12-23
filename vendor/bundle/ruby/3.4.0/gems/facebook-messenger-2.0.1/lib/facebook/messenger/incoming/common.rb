module Facebook
  module Messenger
    module Incoming
      #
      # Common attributes for all incoming data from Facebook.
      #
      module Common
        attr_reader :messaging

        #
        # Assign message to instance variable
        #
        # @param [Object] messaging Object of message.
        #
        def initialize(messaging)
          @messaging = messaging
        end

        #
        # Function return PSID of sender.
        #
        # @see https://developers.facebook.com/docs/messenger-platform/identity
        #   Info about PSID.
        # @see https://developers.facebook.com/docs/messenger-platform/webhook#format
        #   Webhook event format.
        #
        # @return [String] PSID of sender.
        #
        def sender
          @messaging['sender']
        end

        #
        # Function return id of the page from which the message has arrived.
        #
        # @return [String] Facebook page id.
        #
        def recipient
          @messaging['recipient']
        end

        #
        # If the user responds to your message, the appropriate event
        # (messages, messaging_postbacks, etc.) will be sent to your webhook,
        # with a prior_message object appended. The prior_message object
        # includes the source of the message the user is responding to, as well
        # as the user_ref used for the original message send.
        #
        # @return [Hash] The 'prior_message' hash.
        #
        def prior_message
          @messaging['prior_message']
        end

        #
        # Function return timestamp when message is sent.
        #
        # @return [Object] Message time sent.
        #
        def sent_at
          Time.at(@messaging['timestamp'] / 1000)
        end

        #
        # Function send sender_action of 'typing_on' to sender.
        # @see https://developers.facebook.com/docs/messenger-platform/send-messages/sender-actions
        #   Info about sender actions.
        #
        # @return Send message to sender.
        #
        def typing_on
          payload = {
            recipient: sender,
            sender_action: 'typing_on'
          }

          Facebook::Messenger::Bot.deliver(payload, page_id: recipient['id'])
        end

        #
        # Function send sender_action of 'typing_off' to sender.
        # @see https://developers.facebook.com/docs/messenger-platform/send-messages/sender-actions
        #   Info about sender actions.
        #
        # @return Send message to sender.
        #
        def typing_off
          payload = {
            recipient: sender,
            sender_action: 'typing_off'
          }

          Facebook::Messenger::Bot.deliver(payload, page_id: recipient['id'])
        end

        #
        # Function send sender_action of 'mark_seen' to sender.
        # @see https://developers.facebook.com/docs/messenger-platform/send-messages/sender-actions
        #   Info about sender actions.
        #
        # @return Send message to sender.
        #
        def mark_seen
          payload = {
            recipient: sender,
            sender_action: 'mark_seen'
          }

          Facebook::Messenger::Bot.deliver(payload, page_id: recipient['id'])
        end

        #
        # Send reply to sender.
        #
        # @param [Hash] message Hash defining the message.
        #
        # @return Send reply to sender.
        #
        def reply(message)
          payload = {
            recipient: sender,
            message: message,
            message_type: Facebook::Messenger::Bot::MessageType::RESPONSE
          }

          Facebook::Messenger::Bot.deliver(payload, page_id: recipient['id'])
        end
      end
    end
  end
end
