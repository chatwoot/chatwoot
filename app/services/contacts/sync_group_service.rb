class Contacts::SyncGroupService
  pattr_initialize [:contact!, { soft: false, channel: nil }]

  def perform
    validate_group_contact!

    channel = self.channel || contact.group_channel
    raise ActionController::BadRequest, I18n.t('contacts.sync_group.no_supported_inbox') unless syncable?(channel)

    conversation = find_or_create_sync_conversation(channel)
    raise ActionController::BadRequest, I18n.t('contacts.sync_group.no_supported_inbox') if conversation.blank?

    channel.sync_group(conversation, soft: soft)

    contact.reload
    dispatch_group_synced_event
    contact
  end

  private

  # Answering the method is not the same as being able to carry it out. An inbox on the
  # session layer that takes group conversations and answers no group commands responds
  # to `sync_group` and then returns without syncing, so without this the endpoint would
  # build a conversation, dispatch CONTACT_GROUP_SYNCED and report success over a roster
  # nobody read.
  #
  # Reported as the inbox not supporting group sync, which is what it is, and which is
  # what this refusal already says for a channel that has no such method at all.
  #
  # Asked only of the providers the split applies to. A legacy provider's own service
  # decides for itself whether it can sync, and reading the descriptor's capability list
  # for one would newly refuse this endpoint whenever the installation-wide groups switch
  # is off -- a reach this change has no business extending.
  def syncable?(channel)
    return false if channel.blank? || !channel.respond_to?(:sync_group)
    return true unless Whatsapp::Session::Registry.session_backed?(channel)

    Whatsapp::Session::Registry.capabilities_for(channel).include?('group_management')
  end

  def find_or_create_sync_conversation(channel)
    contact_inbox = sync_contact_inbox(channel)
    return nil if contact_inbox.blank?

    contact_inbox.conversations.where(status: %i[open pending]).last ||
      contact_inbox.conversations.order(created_at: :desc).first ||
      create_group_conversation(contact_inbox)
  end

  # A caller that supplied a channel means "sync this group as that inbox sees it", so
  # the thread has to come from that inbox too. Taking the contact's first contact_inbox
  # would drive the supplied channel with a conversation belonging to another one, and
  # write the result into whichever inbox happened to be first.
  def sync_contact_inbox(channel)
    return contact.contact_inboxes.first if self.channel.blank?

    contact.contact_inboxes.find_by(inbox: channel.inbox)
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

  # The channel travels with the event because the payload it builds answers "who are we
  # in this group", and that is per inbox. Without it the listener falls back to the
  # contact's first contact inbox, which can be another number entirely.
  def dispatch_group_synced_event
    Rails.configuration.dispatcher.dispatch(
      Events::Types::CONTACT_GROUP_SYNCED,
      Time.zone.now,
      contact: contact,
      channel: channel || contact.group_channel
    )
  end
end
