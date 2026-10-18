class Labels::UpdateService
  pattr_initialize [:new_label_title!, :old_label_title!, :account_id!]

  def perform
    update_records(tagged_conversations, 'conversation.updated')
    update_records(tagged_contacts, 'contact.updated')
  end

  private

  def update_records(records, event_name)
    records.find_in_batches do |batch|
      batch.each do |record|
        update_record_labels(record)
        broadcast_update(record, event_name)
      end
    end
  end

  def update_record_labels(record)
    record.label_list.remove(old_label_title)
    record.label_list.add(new_label_title)
    record.save!
  end

  def broadcast_update(record, event_name)
    event_data = { record.class.name.downcase.to_sym => record }
    event = Events::Base.new(event_name, Time.zone.now, event_data)

    if record.is_a?(Conversation)
      ActionCableListener.instance.conversation_updated(event)
    else
      ActionCableListener.instance.contact_updated(event)
    end
  end

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
