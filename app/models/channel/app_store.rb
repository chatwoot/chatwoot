class Channel::AppStore < ApplicationRecord
  include Channelable

  self.table_name = 'channel_app_store'

  EDITABLE_ATTRS = [:app_id, :bundle_id, :app_name, :issuer_id, :key_id, :private_key, { provider_config: {} }].freeze

  API_BASE_URL = 'https://api.appstoreconnect.apple.com'.freeze
  REVIEWS_PAGE_SIZE = 200
  SYNC_INTERVAL = 1.hour

  if Chatwoot.encryption_configured?
    encrypts :issuer_id
    encrypts :key_id
    encrypts :private_key
  end

  validates :app_id, presence: true, uniqueness: { scope: :account_id }
  validates :issuer_id, :key_id, :private_key, presence: true
  validate :validate_app_access, on: :create

  before_validation :normalize_auth_fields

  after_create_commit :enqueue_initial_review_fetch

  def name
    'App Store'
  end

  def sync_due?
    last_synced_at.nil? || last_synced_at < SYNC_INTERVAL.ago
  end

  def fetch_reviews
    app_store_client.fetch_reviews(since: last_synced_at)
  end

  def reply_to_review(review_id, response_body)
    response = app_store_client.create_or_update_review_response(review_id, response_body)

    response['id']
  end

  def app_store_client
    @app_store_client ||= AppStoreConnect::Client.new(channel: self)
  end

  private

  def normalize_auth_fields
    self.app_id = app_id.to_s.strip
    self.issuer_id = issuer_id.to_s.strip
    self.key_id = key_id.to_s.strip
    self.private_key = private_key.to_s.gsub('\n', "\n").gsub("\r\n", "\n").strip
  end

  def validate_app_access
    app = app_store_client.fetch_app
    self.app_name = app.dig('attributes', 'name') if app_name.blank?
    self.bundle_id = app.dig('attributes', 'bundleId') if bundle_id.blank?
  rescue StandardError => e
    errors.add(:base, e.message)
  end

  def enqueue_initial_review_fetch
    ::Inboxes::FetchAppStoreReviewsJob.perform_later(self)
  end
end
