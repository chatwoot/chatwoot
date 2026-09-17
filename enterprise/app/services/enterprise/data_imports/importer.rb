module Enterprise::DataImports::Importer
  private

  def create_contact(contact_payload)
    super.tap { |contact| enqueue_imported_contact(contact) }
  end

  def update_existing_contact(contact, contact_payload)
    super.tap { |updated_contact| enqueue_imported_contact(updated_contact) }
  end

  def enqueue_imported_contact(contact)
    ::SearchIndexing::Producer.enqueue(entity: 'contacts', account_id: contact.account_id, ids: [contact.id])
    ::SearchIndexing::Producer.enqueue(entity: 'contact_conversations', account_id: contact.account_id, ids: [contact.id])
  end

  def create_conversation(...)
    super.tap do |conversation|
      ::SearchIndexing::Producer.enqueue(entity: 'conversations', account_id: conversation.account_id, ids: [conversation.id])
    end
  end

  def update_conversation_activity(conversation)
    super
    ::SearchIndexing::Producer.enqueue(entity: 'conversations', account_id: conversation.account_id, ids: [conversation.id])
  end
end
