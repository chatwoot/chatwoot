class Labels::UpdateService
  pattr_initialize [:new_label_title!, :old_label_title!, :account_id!]

  def perform
    tagged_conversations.find_in_batches do |conversation_batch|
      conversation_batch.each do |conversation|
        conversation.label_list.remove(old_label_title)
        conversation.label_list.add(new_label_title)
        conversation.save!
      end
    end

    tagged_contacts.find_in_batches do |contact_batch|
      contact_batch.each do |contact|
        contact.label_list.remove(old_label_title)
        contact.label_list.add(new_label_title)
        contact.save!
      end
    end
  end

  private

  def tagged_conversations
    account.conversations.tagged_with(old_label_title)
  end

  def tagged_contacts
    account.contacts.tagged_with(old_label_title)
  end

  def account
    @account ||= Account.find(account_id)
  end
end
