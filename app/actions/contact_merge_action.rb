class ContactMergeAction
  pattr_initialize [:account!, :base_contact!, :mergee_contact!]

  def perform
    ActiveRecord::Base.transaction do
      validate_contacts
      merge_conversations
      merge_contact_inboxes
      remove_mergee_contact
    end
  end

  private

  def validate_contacts
    return if belongs_to_account?(@base_contact) && belongs_to_account?(@mergee_contact)

    raise Exception, 'contact does not belong to the account'
  end

  def belongs_to_account?(contact)
    @account.id == contact.account_id
  end

  def merge_conversations
    Conversation.where(contact_id: @mergee_contact.id).update(contact_id: @base_contact.id)
  end

  def merge_contact_inboxes
    ContactInbox.where(contact_id: @mergee_contact.id).update(contact_id: @base_contact.id)
  end

  def remove_mergee_contact
    @mergee_contact.destroy!
  end
end
