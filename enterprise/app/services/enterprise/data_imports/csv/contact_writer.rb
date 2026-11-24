module Enterprise::DataImports::Csv::ContactWriter
  private

  def persist(contact)
    identity_changed = contact.changes.keys.intersect?(::SearchIndexing::ConversationDocument::CONTACT_FIELDS)
    super.tap do |saved_contact|
      next unless identity_changed

      ActiveRecord.after_all_transactions_commit { ::SearchIndexing::Conversations.refresh_contact(saved_contact) }
    end
  end
end
