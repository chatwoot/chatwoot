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
  end
end
