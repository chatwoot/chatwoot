# == Schema Information
#
# Table name: channel_instagram
#
#  id               :bigint           not null, primary key
#  access_token     :string           not null
#  auth_type        :string           default("instagram_login"), not null
#  expires_at       :datetime
#  provider_name    :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :integer          not null
#  configuration_id :string
#  instagram_id     :string           not null
#
# Indexes
#
#  index_channel_instagram_on_instagram_id  (instagram_id) UNIQUE
#
class Channel::Instagram < ApplicationRecord
  include Channelable
  include Reauthorizable
  self.table_name = 'channel_instagram'

  # TODO: Remove guard once encryption keys become mandatory (target 3-4 releases out).
  encrypts :access_token if Chatwoot.encryption_configured?

  AUTHORIZATION_ERROR_THRESHOLD = 1

  enum :auth_type, { instagram_login: 'instagram_login', unified_login: 'unified_login' }

  validates :access_token, presence: true
  validates :access_token, length: { maximum: ->(channel) { channel.unified_login? ? MAX_TEXT_COLUMN_LENGTH : MAX_STRING_COLUMN_LENGTH } }
  validates :instagram_id, uniqueness: true, presence: true

  after_create_commit :subscribe, unless: :unified_login?
  before_destroy :unsubscribe

  def name
    'Instagram'
  end

  def create_contact_inbox(instagram_id, name)
    @contact_inbox = ::ContactInboxWithContactBuilder.new({
                                                            source_id: instagram_id,
                                                            inbox: inbox,
                                                            contact_attributes: { name: name }
                                                          }).perform
  end

  def subscribe
    subscribe!
  rescue StandardError => e
    raise if unified_login?

    Rails.logger.debug { "Rescued: #{e.inspect}" }
    true
  end

  def subscribe!
    return Instagram::UnifiedLoginService.new(access_token: access_token).subscribe(instagram_id) if unified_login?

    # ref https://developers.facebook.com/docs/instagram-platform/webhooks#enable-subscriptions
    response = HTTParty.post(
      "#{base_uri}/#{instagram_id}/subscribed_apps",
      query: {
        subscribed_fields: %w[messages message_reactions messaging_seen comments],
        access_token: access_token
      }
    )
    raise Instagram::ConnectionError, I18n.t('instagram.subscription_failed') unless response.success? && response.parsed_response['success'] == true

    response
  end

  def unsubscribe
    token = unified_login? ? self[:access_token] : access_token
    HTTParty.delete(
      "#{base_uri}/#{instagram_id}/subscribed_apps",
      query: {
        access_token: token
      }
    )
    true
  rescue StandardError => e
    Rails.logger.debug { "Rescued: #{e.inspect}" }
    true
  end

  def access_token
    return Instagram::RefreshOauthTokenService.new(channel: self).access_token unless unified_login?

    prompt_reauthorization! if persisted? && expires_at.present? && expires_at <= Time.current && !reauthorization_required?
    self[:access_token]
  end

  def authorization_error!
    return if unified_login? && reauthorization_required?

    super
  end

  def find_message_by_source_id(source_id)
    return if source_id.blank?

    source_ids = unified_login? ? Instagram::MessageId.aliases(source_id) : [source_id]
    inbox.messages.find_by(source_id: source_ids)
  end

  def base_uri
    host = unified_login? ? 'graph.facebook.com' : 'graph.instagram.com'
    "https://#{host}/#{GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')}"
  end
end
