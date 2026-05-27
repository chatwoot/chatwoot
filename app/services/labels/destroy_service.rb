class Labels::DestroyService
  pattr_initialize [:label_title!, :account_id!, :label_deleted_at!]

  def perform
    remove_conversation_labels
    remove_contact_labels
  end

  private

  def remove_conversation_labels
    tagged_conversations.find_in_batches do |conversation_batch|
      conversation_batch.each do |conversation|
        update_conversation_cached_labels(conversation)
      end
      delete_label_taggings('Conversation', conversation_batch.map(&:id))
    end
  end

  def remove_contact_labels
    contact_label_taggings.in_batches do |tagging_batch|
      ActsAsTaggableOn::Tagging.where(id: tagging_batch.select(:id)).delete_all
    end
  end

  def update_conversation_cached_labels(conversation)
    label_list = conversation.label_list.dup
    label_list.remove(label_title)

    # We only want the acts-as-taggable-on cache effect here, not Conversation callbacks/events.
    # rubocop:disable Rails/SkipsModelValidations
    conversation.update_column(:cached_label_list, label_list.join("#{ActsAsTaggableOn.delimiter} "))
    # rubocop:enable Rails/SkipsModelValidations
  end

  def tagged_conversations
    account.conversations.where(id: label_taggings_for('Conversation').select(:taggable_id))
  end

  def contact_label_taggings
    label_taggings_for('Contact').where(taggable_id: account.contacts.select(:id))
  end

  def delete_label_taggings(taggable_type, taggable_ids)
    ActsAsTaggableOn::Tagging
      .where(id: label_taggings_for(taggable_type).where(taggable_id: taggable_ids).select(:id))
      .delete_all
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
