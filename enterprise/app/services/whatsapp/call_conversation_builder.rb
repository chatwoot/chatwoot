class Whatsapp::CallConversationBuilder
  pattr_initialize [:inbox!, :contact!, :user!]

  # Mirrors the continuity rule in Whatsapp::IncomingMessageBaseService#set_conversation.
  def existing_conversation
    conversations = inbox.conversations.where(contact_id: contact.id)
    conversations = conversations.where.not(status: :resolved) unless inbox.lock_to_single_conversation
    # Only threads the caller can open, else a newest-but-hidden thread would block the call.
    conversations = Conversations::PermissionFilterService.new(conversations, user, inbox.account).perform
    conversations.order(last_activity_at: :desc).first
  end

  # Unsaved, so callers can authorize the thread a call would open before dialing.
  def new_conversation
    inbox.account.conversations.new(inbox: inbox, contact: contact, assignee_id: user.id, status: :open)
  end

  # Locked so two agents calling the same fresh contact can't open two threads.
  def perform!
    contact_inbox = ContactInboxBuilder.new(contact: contact, inbox: inbox).perform

    contact_inbox.with_lock do
      existing_conversation || new_conversation.tap { |conversation| conversation.update!(contact_inbox: contact_inbox) }
    end
  end
end
