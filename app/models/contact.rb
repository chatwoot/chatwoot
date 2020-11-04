# == Schema Information
#
# Table name: contacts
#
#  id                    :integer          not null, primary key
#  additional_attributes :jsonb
#  custom_attributes     :jsonb
#  email                 :string
#  identifier            :string
#  name                  :string
#  phone_number          :string
#  pubsub_token          :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :integer          not null
#
# Indexes
#
#  index_contacts_on_account_id         (account_id)
#  index_contacts_on_pubsub_token       (pubsub_token) UNIQUE
#  uniq_email_per_account_contact       (email,account_id) UNIQUE
#  uniq_identifier_per_account_contact  (identifier,account_id) UNIQUE
#

class Contact < ApplicationRecord
  include Pubsubable
  include Avatarable
  include AvailabilityStatusable

  validates :account_id, presence: true
  validates :email, allow_blank: true, uniqueness: { scope: [:account_id], case_sensitive: false }
  validates :identifier, allow_blank: true, uniqueness: { scope: [:account_id] }

  belongs_to :account
  has_many :conversations, dependent: :destroy
  has_many :contact_inboxes, dependent: :destroy
  has_many :inboxes, through: :contact_inboxes
  has_many :messages, as: :sender, dependent: :destroy

  before_validation :prepare_email_attribute
  after_create_commit :dispatch_create_event
  after_update_commit :dispatch_update_event
  after_commit :ip_lookup

  def get_source_id(inbox_id)
    contact_inboxes.find_by!(inbox_id: inbox_id).source_id
  end

  def push_event_data
    {
      additional_attributes: additional_attributes,
      email: email,
      id: id,
      identifier: identifier,
      name: name,
      phone_number: phone_number,
      pubsub_token: pubsub_token,
      thumbnail: avatar_url,
      type: 'contact'
    }
  end

  def webhook_data
    {
      id: id,
      name: name,
      avatar: avatar_url,
      type: 'contact'
    }
  end

  def ip_lookup
    return unless account.feature_enabled?('ip_lookup')

    ContactIpLookupJob.perform_later(self)
  end

  def prepare_email_attribute
    # So that the db unique constraint won't throw error when email is ''
    self.email = nil if email.blank?
    email.downcase! if email.present?
  end

  def dispatch_create_event
    Rails.configuration.dispatcher.dispatch(CONTACT_CREATED, Time.zone.now, contact: self)
  end

  def dispatch_update_event
    Rails.configuration.dispatcher.dispatch(CONTACT_UPDATED, Time.zone.now, contact: self)
  end
end
