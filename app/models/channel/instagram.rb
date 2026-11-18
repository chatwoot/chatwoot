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
  include Instagram::RequestOptions
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
                                                            contact_attributes: { name: name, identifier: instagram_id }
                                                          }).perform
  end

  def subscribe
    subscribe!
    true
  rescue StandardError => e
    raise if unified_login?

    subscription_failed(subscription_failure_reason(e))
  end

  def subscribe!
    return Instagram::UnifiedLoginService.new(access_token: access_token).subscribe(instagram_id) if unified_login?

    # ref https://developers.facebook.com/docs/instagram-platform/webhooks#enable-subscriptions
    response = HTTParty.post(
      "#{base_uri}/#{instagram_id}/subscribed_apps",
      query: {
        subscribed_fields: %w[messages message_reactions messaging_seen],
        access_token: access_token
      },
      **INSTAGRAM_SHORT_REQUEST_OPTIONS
    )
    raise Instagram::ConnectionError, I18n.t('instagram.subscription_failed') unless response.success? && response.parsed_response['success'] == true

    response
  end

  def subscription_failure_reason(error)
    return 'Instagram did not confirm the subscription' if error.is_a?(Instagram::ConnectionError)

    "the request did not complete: #{error.class}"
  end

  # An inbox that did not subscribe exists and receives nothing, and it used to say so
  # nowhere: the answer was never read, every failure answered `true`, and the only trace
  # was a `debug` line. The operator saw a working inbox and no messages.
  #
  # There is no third state worth reporting here. Instagram refusing and Instagram not
  # answering leave the same inbox in the same condition, and they have the same remedy,
  # which is the one the reauthorization banner already asks for: reconnect, which runs
  # this again. `authorization_error!` rather than `prompt_reauthorization!` so the
  # channel's own threshold decides, which for this channel is one.
  def subscription_failed(reason)
    Rails.logger.error("[INSTAGRAM] inbox #{inbox&.id} did not subscribe to webhooks, so it will receive nothing: #{reason}")
    authorization_error!
    false
  end

  # Failing to unsubscribe must not stop the channel from being removed: the operator
  # asked for it to go, and Instagram's copy of the subscription is not ours to hold it
  # hostage. But it cannot be silent either, because we go on receiving webhooks for an
  # inbox that no longer exists, and the only way anyone finds out is by reading logs.
  def unsubscribe
    token = unified_login? ? self[:access_token] : access_token
    response = HTTParty.delete(
      "#{base_uri}/#{instagram_id}/subscribed_apps",
      query: {
        access_token: token
      },
      **INSTAGRAM_SHORT_REQUEST_OPTIONS
    )
    return true if response.success?

    log_unsubscribe_failure("Instagram answered #{response.code}")
  rescue StandardError => e
    log_unsubscribe_failure("the request did not complete: #{e.class}")
  end

  def log_unsubscribe_failure(reason)
    Rails.logger.error(
      "[INSTAGRAM] account #{account_id} removed instagram id #{instagram_id} and it is still subscribed there: #{reason}"
    )
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
