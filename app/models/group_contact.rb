# == Schema Information
#
# Table name: group_contacts
#
#  id              :bigint           not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  contact_id      :bigint           not null
#  conversation_id :bigint           not null
#
# Indexes
#
#  index_group_contacts_on_account_id                   (account_id)
#  index_group_contacts_on_contact_id                   (contact_id)
#  index_group_contacts_on_conversation_id              (conversation_id)
#  index_group_contacts_on_conversation_id_and_contact_id  (conversation_id,contact_id) UNIQUE
#
class GroupContact < ApplicationRecord
  validates :account_id, presence: true
  validates :conversation_id, presence: true
  validates :contact_id, presence: true
  validates :contact_id, uniqueness: { scope: [:conversation_id] }
  validate :ensure_conversation_is_group
  validate :ensure_contact_belongs_to_account

  belongs_to :account
  belongs_to :conversation
  belongs_to :contact

  before_validation :ensure_account_id

  after_create_commit :dispatch_contact_added_event
  after_destroy_commit :dispatch_contact_removed_event

  private

  def ensure_account_id
    self.account_id = conversation&.account_id
  end

  def ensure_conversation_is_group
    errors.add(:conversation, 'must be a group conversation') if conversation && !conversation.group?
  end

  def ensure_contact_belongs_to_account
    errors.add(:contact, 'must belong to the same account') if contact && conversation && contact.account_id != conversation.account_id
  end

  def dispatch_contact_added_event
    Rails.configuration.dispatcher.dispatch(
      CONVERSATION_CONTACT_ADDED,
      Time.zone.now,
      conversation: conversation,
      contact: contact
    )
  end

  def dispatch_contact_removed_event
    Rails.configuration.dispatcher.dispatch(
      CONVERSATION_CONTACT_REMOVED,
      Time.zone.now,
      conversation: conversation,
      contact: contact
    )
  end
end
