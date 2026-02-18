# == Schema Information
#
# Table name: channel_x
#
#  id                         :bigint           not null, primary key
#  account_id                 :bigint           not null
#  profile_id                 :string           not null
#  username                   :string           not null
#  name                       :string
#  profile_image_url          :string
#  bearer_token               :string
#  refresh_token              :string
#  token_expires_at           :datetime
#  refresh_token_expires_at   :datetime
#  authorization_error_count  :integer          default(0)
#  webhook_id                 :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#

class Channel::X < ApplicationRecord
  include Channelable
  include Reauthorizable

  self.table_name = 'channel_x'

  encrypts :bearer_token if Chatwoot.encryption_configured?
  encrypts :refresh_token if Chatwoot.encryption_configured?

  AUTHORIZATION_ERROR_THRESHOLD = 1

  validates :profile_id, presence: true, uniqueness: true
  validates :username, presence: true
  validates :account_id, presence: true

  belongs_to :account

  after_create_commit :subscribe_to_webhook
  before_destroy :unsubscribe_from_webhook

  def token_expired?
    return true if token_expires_at.blank?

    Time.current >= token_expires_at
  end

  def refresh_token_valid?
    return false if refresh_token_expires_at.blank?

    Time.current < refresh_token_expires_at
  end

  def client
    @client ||= X::Client.new(bearer_token: bearer_token)
  end

  def name
    'X'
  end

  def subscribe_to_webhook
    X::SubscriptionService.new(channel: self).subscribe
  rescue StandardError => e
    Rails.logger.error("Failed to subscribe X user to webhook: #{e.message}")
  end

  private

  def unsubscribe_from_webhook
    X::SubscriptionService.new(channel: self).unsubscribe
  rescue StandardError => e
    Rails.logger.error("Failed to unsubscribe X user from webhook: #{e.message}")
    true
  end
end
