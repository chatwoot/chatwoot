class Contacts::SyncGroupService
  pattr_initialize [:contact!, { soft: false }]

  def perform
    validate_group_contact!

    channel = contact.group_channel
    raise ActionController::BadRequest, I18n.t('contacts.sync_group.no_supported_inbox') if channel.blank? || !channel.respond_to?(:sync_group)

    conversation = find_or_create_sync_conversation
    raise ActionController::BadRequest, I18n.t('contacts.sync_group.no_supported_inbox') if conversation.blank?

    channel.sync_group(conversation, soft: soft)

    contact.reload
    dispatch_group_synced_event
    contact
  end

  private

  def find_or_create_sync_conversation
    contact_inbox = contact.contact_inboxes.first
    return nil if contact_inbox.blank?

    contact_inbox.conversations.where(status: %i[open pending]).last ||
      contact_inbox.conversations.order(created_at: :desc).first ||
      create_group_conversation(contact_inbox)
  end

  def create_group_conversation(contact_inbox)
    Conversation.create!(
      account_id: contact_inbox.inbox.account_id,
      inbox_id: contact_inbox.inbox_id,
      contact_id: contact.id,
      contact_inbox_id: contact_inbox.id,
      group_type: :group
    )
  end

  def validate_group_contact!
    raise ActionController::BadRequest, I18n.t('contacts.sync_group.not_a_group') if contact.group_type_individual?
    raise ActionController::BadRequest, I18n.t('contacts.sync_group.no_identifier') if contact.identifier.blank?
  end

  def dispatch_group_synced_event
    Rails.configuration.dispatcher.dispatch(
      Events::Types::CONTACT_GROUP_SYNCED,
      Time.zone.now,
      contact: contact
    )
  end
end
