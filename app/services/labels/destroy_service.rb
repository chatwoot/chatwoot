class Labels::DestroyService
  pattr_initialize [:label_title!, :account_id!]

  def perform
    tagged_conversations.find_in_batches do |conversation_batch|
      conversation_batch.each do |conversation|
        remove_label(conversation)
      end
    end

    tagged_contacts.find_in_batches do |contact_batch|
      contact_batch.each do |contact|
        remove_label(contact)
      end
    end
  end

  private

  def remove_label(record)
    record.label_list.remove(label_title)
    record.save!
  end

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
