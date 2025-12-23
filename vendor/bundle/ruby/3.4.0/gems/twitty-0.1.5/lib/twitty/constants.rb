# frozen_string_literal: true

module Twitty::Constants
  API_CONFIG = {
    fetch_webhooks: {
      method: :get,
      endpoint: '/1.1/account_activity/all/%<env>s/webhooks.json',
      required_params: []
    },

    register_webhook: {
      method: :post,
      endpoint: '/1.1/account_activity/all/%<env>s/webhooks.json?url=%<url>s',
      required_params: [:url]
    },

    unregister_webhook: {
      method: :delete,
      endpoint: '/1.1/account_activity/all/%<env>s/webhooks/%<id>s.json',
      required_params: [:id]
    },

    fetch_subscriptions: {
      method: :get,
      endpoint: '/1.1/account_activity/all/%<env>s/subscriptions.json',
      required_params: []
    },

    create_subscription: {
      method: :post,
      endpoint: '/1.1/account_activity/all/%<env>s/subscriptions.json',
      required_params: []
    },

    remove_subscription: {
      method: :delete,
      endpoint: '/1.1/account_activity/all/%<env>s/subscriptions/%<user_id>s.json',
      required_params: [:user_id]
    },

    send_direct_message: {
      method: :post,
      endpoint: '/1.1/direct_messages/events/new.json',
      required_params: [:message, :recipient_id]
    },

    send_tweet_reply: {
      method: :post,
      endpoint: '/1.1/statuses/update.json',
      required_params: [:tweet, :reply_to_tweet_id]
    },

    request_oauth_token: {
      method: :post,
      endpoint: '/oauth/request_token',
      required_params: [:url]
    },

    access_token: {
      method: :post,
      endpoint: '/oauth/access_token',
      required_params: [:oauth_token, :oauth_verifier]
    },

    destroy_tweet: {
      method: :post,
      endpoint: '/1.1/statuses/destroy/%<tweet_id>s.json',
      required_params: [:tweet_id]
    },

    retweet: {
      method: :post,
      endpoint: '/1.1/statuses/retweet/%<tweet_id>s.json',
      required_params: [:tweet_id]
    },

    unretweet: {
      method: :post,
      endpoint: '/1.1/statuses/unretweet/%<tweet_id>s.json',
      required_params: [:tweet_id]
    },

    like_tweet: {
      method: :post,
      endpoint: '/1.1/favorites/create.json',
      required_params: [:tweet_id]
    },

    unlike_tweet: {
      method: :post,
      endpoint: '/1.1/favorites/destroy.json',
      required_params: [:tweet_id]
    },

    user_show: {
      method: :get,
      endpoint: '/1.1/users/show.json?screen_name=%<screen_name>s',
      required_params: [:screen_name]
    }
  }.freeze
end
