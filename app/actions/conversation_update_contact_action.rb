class ConversationUpdateContactAction
  include Events::Types
  pattr_initialize [:account!, :conversation!, :contact!]
  def perform
    @old_contact = @conversation.contact

    ActiveRecord::Base.transaction do
      validate_contacts
      update_conversation
      update_contact_inbox
      update_messages
    end

    return @conversation
  end

  private

  def update_contact_inbox
    @conversation.contact_inbox.update(contact_id: @contact.id)
  end

  def validate_contacts
    return if belongs_to_account?(@conversation.contact) && belongs_to_account?(@contact)

    raise StandardError, 'contact does not belong to the account'
  end

  def belongs_to_account?(contact)
    @account.id == contact.account_id
  end

  def update_conversation
    @conversation.update(contact_id: @contact.id)
  end

  def update_messages
    conversation.messages.where(sender: @old_contact).update(sender: @contact)
  end
end
