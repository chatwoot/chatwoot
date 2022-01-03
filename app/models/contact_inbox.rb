# == Schema Information
#
# Table name: contact_inboxes
#
#  id            :bigint           not null, primary key
#  hmac_verified :boolean          default(FALSE)
#  pubsub_token  :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  contact_id    :bigint
#  inbox_id      :bigint
#  source_id     :string           not null
#
# Indexes
#
#  index_contact_inboxes_on_contact_id              (contact_id)
#  index_contact_inboxes_on_inbox_id                (inbox_id)
#  index_contact_inboxes_on_inbox_id_and_source_id  (inbox_id,source_id) UNIQUE
#  index_contact_inboxes_on_pubsub_token            (pubsub_token) UNIQUE
#  index_contact_inboxes_on_source_id               (source_id)
#
# Foreign Keys
#
#  fk_rails_...  (contact_id => contacts.id) ON DELETE => cascade
#  fk_rails_...  (inbox_id => inboxes.id) ON DELETE => cascade
#

class ContactInbox < ApplicationRecord
  include Pubsubable
  validates :inbox_id, presence: true
  validates :contact_id, presence: true
  validates :source_id, presence: true
  validate :valid_source_id_format?

  belongs_to :contact
  belongs_to :inbox

  has_many :conversations, dependent: :destroy_async

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

  private

  def validate_twilio_source_id
    # https://www.twilio.com/docs/glossary/what-e164#regex-matching-for-e164
    if inbox.channel.medium == 'sms' && !/\+[1-9]\d{1,14}\z/.match?(source_id)
      errors.add(:source_id, 'invalid source id for twilio sms inbox. valid Regex /\+[1-9]\d{1,14}\z/')
    elsif inbox.channel.medium == 'whatsapp' && !/whatsapp:\+[1-9]\d{1,14}\z/.match?(source_id)
      errors.add(:source_id, 'invalid source id for twilio whatsapp inbox. valid Regex /whatsapp:\+[1-9]\d{1,14}\z/')
    end
  end

  def validate_email_source_id
    errors.add(:source_id, "invalid source id for Email inbox. valid Regex #{Devise.email_regexp}") unless Devise.email_regexp.match?(source_id)
  end

  def valid_source_id_format?
    validate_twilio_source_id if inbox.channel_type == 'Channel::TwilioSms'
    validate_email_source_id if inbox.channel_type == 'Channel::Email'
  end
end
