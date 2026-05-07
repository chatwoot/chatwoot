class Labels::DestroyService
  pattr_initialize [:label_title!, :account_id!, :label_deleted_at!]

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
    account.conversations.where(id: label_taggings_for('Conversation').select(:taggable_id))
  end

  def tagged_contacts
    account.contacts.where(id: label_taggings_for('Contact').select(:taggable_id))
  end

  def label_taggings_for(taggable_type)
    ActsAsTaggableOn::Tagging
      .joins(:tag)
      .where(context: 'labels', taggable_type: taggable_type, tags: { name: label_title })
      .where('taggings.created_at <= ?', label_deleted_at)
  end

  def account
    @account ||= Account.find(account_id)
  end
end
