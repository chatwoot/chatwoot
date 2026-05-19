# == Schema Information
#
# Table name: channel_google_play
#
#  id              :bigint           not null, primary key
#  app_id          :string           not null
#  provider_config :jsonb            not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#
# Indexes
#
#  index_channel_google_play_on_account_id_and_app_id  (account_id,app_id) UNIQUE
#

class Channel::GooglePlay < ApplicationRecord
  include Channelable

  self.table_name = 'channel_google_play'
  EDITABLE_ATTRS = [:app_id, { provider_config: {} }].freeze

  API_BASE_URL = 'https://androidpublisher.googleapis.com/androidpublisher/v3'.freeze
  # Google Play caps a developer reply at 350 characters
  MAX_REPLY_LENGTH = 350

  validates :app_id, presence: true, uniqueness: { scope: :account_id }

  def name
    'Google Play'
  end

  # Google Play only retains reviews from the last 7 days, hence the channel is polled frequently
  def fetch_reviews
    response = HTTParty.get(
      "#{API_BASE_URL}/applications/#{app_id}/reviews",
      headers: authorization_headers,
      query: { maxResults: 100 }
    )
    raise "Google Play reviews fetch failed (#{response.code}): #{response.body}" unless response.success?

    response.parsed_response['reviews'] || []
  end

  # Returns a stable source_id for the reply so the outgoing message can be marked as sent.
  # Google Play has no separate reply id, so we combine the review id with the developer comment's
  # lastEdited timestamp from the response.
  def reply_to_review(review_id, reply_text)
    response = HTTParty.post(
      "#{API_BASE_URL}/applications/#{app_id}/reviews/#{review_id}:reply",
      headers: authorization_headers.merge('Content-Type' => 'application/json'),
      body: { replyText: reply_text.to_s.truncate(MAX_REPLY_LENGTH) }.to_json
    )
    raise "Google Play reply failed (#{response.code}): #{response.body}" unless response.success?

    last_edited = response.parsed_response.dig('result', 'lastEdited', 'seconds')
    "#{review_id}::reply::#{last_edited}"
  end

  private

  def authorization_headers
    { 'Authorization' => "Bearer #{access_token}" }
  end

  # Channels are connected through the Google OAuth flow; tokens are refreshed on demand
  def access_token
    Google::RefreshOauthTokenService.new(channel: self).access_token
  end
end
