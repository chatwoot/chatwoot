require 'securerandom'

module Crm::GoogleOffline::FeedToken
  ATTRIBUTE_KEY = 'google_feed_token'.freeze

  module_function

  def fetch_or_create!(account)
    account.with_lock do
      token = account.custom_attributes.to_h[ATTRIBUTE_KEY].presence
      next token if token

      SecureRandom.urlsafe_base64(32).tap do |new_token|
        account.update!(custom_attributes: account.custom_attributes.to_h.merge(ATTRIBUTE_KEY => new_token))
      end
    end
  end
end
