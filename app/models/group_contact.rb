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
  attr_accessor :promoted_to_primary

  validates :account_id, presence: true
  validates :conversation_id, presence: true
  validates :contact_id, presence: true
  validates :contact_id, uniqueness: { scope: [:conversation_id] }
  validate :ensure_conversation_is_group
  validate :ensure_contact_belongs_to_account
  validate :ensure_not_primary_contact

  belongs_to :account
  belongs_to :conversation
  belongs_to :contact

  before_validation :ensure_account_id
  after_create :promote_to_primary_if_first_contact

  after_create_commit :dispatch_contact_added_event, unless: :promoted_to_primary
  after_destroy_commit :dispatch_contact_removed_event, unless: :promoted_to_primary

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

  def ensure_not_primary_contact
    errors.add(:contact, 'is already the primary contact') if contact && conversation && conversation.contact_id == contact.id
  end

  def promote_to_primary_if_first_contact
    return unless conversation.group? && conversation.contact_id.nil?

    # Create or find contact_inbox for this contact
    contact_inbox = contact.contact_inboxes.find_or_create_by!(inbox: conversation.inbox) do |ci|
      ci.source_id = contact.phone_number || contact.email || SecureRandom.uuid
    end

    # Update conversation to set this contact as primary
    conversation.update!(contact: contact, contact_inbox: contact_inbox)

    # Mark as promoted so we don't dispatch wrong events
    self.promoted_to_primary = true

    # Remove this group_contact since the contact is now primary
    destroy!
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
