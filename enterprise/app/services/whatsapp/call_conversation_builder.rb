# Resolves the conversation an outbound WhatsApp call belongs to. The dial only needs a phone number, so a
# contact who has never messaged in is callable — we open a conversation for the call to live in.
class Whatsapp::CallConversationBuilder
  pattr_initialize [:inbox!, :contact!, :user!]

  # Same continuity rule inbound messages follow (Whatsapp::IncomingMessageBaseService#set_conversation): when the
  # inbox isn't locked to a single conversation, a resolved thread is left alone and the call opens a new one.
  # Scoped by contact, not contact_inbox: a contact can hold several contact_inbox rows in one inbox.
  def existing_conversation
    conversations = inbox.conversations.where(contact_id: contact.id)
    conversations = conversations.where.not(status: :resolved) unless inbox.lock_to_single_conversation
    conversations.order(last_activity_at: :desc).first
  end

  # Unsaved, so the caller can authorize the thread a call would open before dialing.
  def new_conversation
    inbox.account.conversations.new(inbox: inbox, contact: contact, assignee_id: user.id, status: :open)
  end

  # Locked on the contact_inbox so two agents calling the same fresh contact can't open two threads.
  def perform!
    contact_inbox = ContactInboxBuilder.new(contact: contact, inbox: inbox).perform

    contact_inbox.with_lock do
      existing_conversation || new_conversation.tap { |conversation| conversation.update!(contact_inbox: contact_inbox) }
    end
  end
end
