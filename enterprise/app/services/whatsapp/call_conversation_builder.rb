class Whatsapp::CallConversationBuilder
  pattr_initialize [:inbox!, :contact!, :user!]

  # Mirrors the continuity rule in Whatsapp::IncomingMessageBaseService#set_conversation.
  # Locked inboxes hold each WhatsApp identity to one thread.
  def existing_conversation
    return contact_conversations.first if inbox.lock_to_single_conversation

    # Only threads the caller can open, else a newest-but-hidden thread would block the call.
    Conversations::PermissionFilterService.new(
      contact_conversations.where.not(status: :resolved), user, inbox.account
    ).perform.first
  end

  def contact_conversations
    inbox.conversations.joins(:contact_inbox)
         .where(contact_id: contact.id, contact_inboxes: { source_id: contact.phone_number&.delete('+') })
         .order(last_activity_at: :desc)
  end

  # Unsaved, so callers can authorize the thread a call would open before dialing.
  def new_conversation
    inbox.account.conversations.new(inbox: inbox, contact: contact, assignee_id: user.id, status: :open)
  end

  # Locked so two agents calling the same fresh contact can't open two threads.
  def perform!
    contact_inbox = ContactInboxBuilder.new(contact: contact, inbox: inbox).perform

    conversation = contact_inbox.with_lock do
      existing_conversation || new_conversation.tap { |record| record.update!(contact_inbox: contact_inbox) }
    end

    # Preserve assignment changes through commit callbacks before clearing trigger-populated attributes.
    conversation.tap { |record| record.reload if record.changed? }
  end
end
