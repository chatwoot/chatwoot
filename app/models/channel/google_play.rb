# == Schema Information
#
# Table name: channel_google_play
#
#  id              :bigint           not null, primary key
#  app_id          :string           not null
#  provider_config :jsonb            not null
#  last_synced_at  :datetime
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
  REVIEWS_PAGE_SIZE = 100
  # Safety bound — at 100 per page this covers 5,000 reviews. The API only retains the last 7
  # days, so this is far above any realistic volume and just prevents runaway loops.
  MAX_REVIEW_PAGES = 50
  # Each inbox is synced at most once per this window. The cron runs more frequently
  # so a missed window retries on the next tick.
  SYNC_INTERVAL = 1.hour

  validates :app_id, presence: true, uniqueness: { scope: :account_id }

  # Pull reviews on the agent's behalf the moment the inbox is wired up so they're not waiting
  # for the next 15-minute poll. Runs after the surrounding transaction commits so the
  # associated inbox is guaranteed to be visible.
  after_create_commit :enqueue_initial_review_fetch

  def name
    'Google Play'
  end

  def sync_due?
    last_synced_at.nil? || last_synced_at < SYNC_INTERVAL.ago
  end

  # Google Play only retains reviews from the last 7 days, hence the channel is polled frequently.
  # Pages through tokenPagination.nextPageToken until the API stops returning a cursor.
  def fetch_reviews
    reviews = []
    page_token = nil

    MAX_REVIEW_PAGES.times do
      parsed = fetch_reviews_page(page_token)
      reviews.concat(parsed['reviews'] || [])

      page_token = parsed.dig('tokenPagination', 'nextPageToken')
      break if page_token.blank?
    end

    reviews
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

  def fetch_reviews_page(page_token)
    query = { maxResults: REVIEWS_PAGE_SIZE }
    query[:token] = page_token if page_token.present?

    response = HTTParty.get(
      "#{API_BASE_URL}/applications/#{app_id}/reviews",
      headers: authorization_headers,
      query: query
    )
    raise "Google Play reviews fetch failed (#{response.code}): #{response.body}" unless response.success?

    response.parsed_response
  end

  def authorization_headers
    { 'Authorization' => "Bearer #{access_token}" }
  end

  # Channels are connected through the Google OAuth flow; tokens are refreshed on demand
  def access_token
    Google::RefreshOauthTokenService.new(channel: self).access_token
  end

  def enqueue_initial_review_fetch
    ::Inboxes::FetchGooglePlayReviewsJob.perform_later(self)
  end
end
