class Labels::DestroyService
  pattr_initialize [:label_title!, :account_id!]

  def perform
    tagged_conversations.find_in_batches do |conversation_batch|
      conversation_batch.each do |conversation|
        conversation.label_list.remove(label_title)
        conversation.save!
      end
    end

    tagged_contacts.find_in_batches do |contact_batch|
      contact_batch.each do |contact|
        contact.label_list.remove(label_title)
        contact.save!
      end
    end
  end

  private

  def tagged_conversations
    account.conversations.tagged_with(label_title)
  end

  def tagged_contacts
    account.contacts.tagged_with(label_title)
  end

  def account
    @account ||= Account.find(account_id)
  end
end
