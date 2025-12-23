# frozen_string_literal: true

module Twitty::Payload
  EMPTY_PAYLOAD_ACTIONS = %w[fetch_webhooks register_webhook unregister_webhook fetch_subscriptions
                             create_subscription remove_subscription destroy_tweet retweet unretweet user_show ].freeze

  EMPTY_PAYLOAD_ACTIONS.each do |action|
    define_method "#{action}_payload" do
      {}
    end
  end

  def build_payload(action, payload)
    @payload = payload
    send("#{action}_payload")
  end

  def send_direct_message_payload
    {
      event: {
        type: 'message_create',
        message_create: {
          target: {
            recipient_id: @payload[:recipient_id]
          },
          message_data: {
            text: @payload[:message]
          }
        }
      }
    }.to_json
  end

  def send_tweet_reply_payload
    {
      status: @payload[:tweet],
      in_reply_to_status_id: @payload[:reply_to_tweet_id]
    }
  end

  def request_oauth_token_payload
    {
      oauth_callback: @payload[:url]
    }
  end

  def access_token_payload
    {
      oauth_token: @payload[:oauth_token],
      oauth_verifier: @payload[:oauth_verifier]
    }
  end

  def like_tweet_payload
    {
      id: @payload[:tweet_id]
    }
  end

  def unlike_tweet_payload
    {
      id: @payload[:tweet_id]
    }
  end
end
