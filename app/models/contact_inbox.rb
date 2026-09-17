# == Schema Information
#
# Table name: contact_inboxes
#
#  id            :bigint           not null, primary key
#  hmac_verified :boolean          default(FALSE)
#  pubsub_token  :string
#  widget_token_version :integer          default(0), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  contact_id    :bigint
#  inbox_id      :bigint
#  source_id     :text             not null
#
# Indexes
#
#  index_contact_inboxes_on_contact_id              (contact_id)
#  index_contact_inboxes_on_inbox_id                (inbox_id)
#  index_contact_inboxes_on_inbox_id_and_source_id  (inbox_id,source_id) UNIQUE
#  index_contact_inboxes_on_pubsub_token            (pubsub_token) UNIQUE
#  index_contact_inboxes_on_source_id               (source_id)
#

class ContactInbox < ApplicationRecord
  include Pubsubable
  include RegexHelper
  validates :inbox_id, presence: true
  validates :contact_id, presence: true
  validates :source_id, presence: true
  validate :valid_source_id_format?

  belongs_to :contact
  belongs_to :inbox

  has_many :conversations, dependent: :destroy_async

  # contact_inboxes that are not associated with any conversation
  scope :stale_without_conversations, lambda { |time_period|
    left_joins(:conversations)
      .where('contact_inboxes.created_at < ?', time_period)
      .where(conversations: { contact_id: nil })
  }

  def webhook_data
    {
      id: id,
      contact: contact.try(:webhook_data),
      inbox: inbox.webhook_data,
      account: inbox.account.webhook_data,
      current_conversation: current_conversation.try(:webhook_data),
      source_id: source_id
    }
  end

  def current_conversation
    conversations.last
  end

  # Legacy JWTs omit token_version and are treated as version 0.
  def valid_widget_token?(decoded)
    return false if decoded.blank?

    claimed = decoded[:token_version]
    claimed_version = claimed.nil? ? 0 : claimed.to_i
    claimed_version == widget_token_version.to_i
  end

  # Re-checks the presented JWT under a row lock so a concurrent request that
  # already rotated cannot write PII and receive a fresh token.
  def with_current_widget_token(decoded)
    with_lock do
      raise ActiveRecord::RecordNotFound unless valid_widget_token?(decoded)

      yield
    end
  end

  def rotate_widget_token!
    with_lock do
      rotate_widget_session_secrets!
      Widget::TokenService.new(payload: Widget::TokenService.payload_for(self)).generate_token
    end
  end

  def invalidate_widget_token!
    with_lock do
      rotate_widget_session_secrets!
    end
  end

  private

  def rotate_widget_session_secrets!
    update!(
      widget_token_version: widget_token_version + 1,
      pubsub_token: self.class.generate_unique_secure_token
    )
  end

  def validate_twilio_source_id
    # https://www.twilio.com/docs/glossary/what-e164#regex-matching-for-e164
    if inbox.channel.medium == 'sms' && !TWILIO_CHANNEL_SMS_REGEX.match?(source_id)
      errors.add(:source_id, "invalid source id for twilio sms inbox. valid Regex #{TWILIO_CHANNEL_SMS_REGEX}")
    elsif inbox.channel.medium == 'whatsapp' && !TWILIO_CHANNEL_WHATSAPP_REGEX.match?(source_id)
      errors.add(:source_id, "invalid source id for twilio whatsapp inbox. valid Regex #{TWILIO_CHANNEL_WHATSAPP_REGEX}")
    end
  end

  def validate_whatsapp_source_id
    return if WHATSAPP_CHANNEL_REGEX.match?(source_id)

    errors.add(:source_id, "invalid source id for whatsapp inbox. valid Regex #{WHATSAPP_CHANNEL_REGEX}")
  end

  def valid_source_id_format?
    validate_twilio_source_id if inbox.channel_type == 'Channel::TwilioSms'
    validate_whatsapp_source_id if inbox.channel_type == 'Channel::Whatsapp'
  end
end
