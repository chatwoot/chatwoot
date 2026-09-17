module Enterprise::Internal::RemoveStaleContactsService
  private

  def contacts_removed(contact_ids)
    ::SearchIndexing::Producer.enqueue(entity: 'contacts', account_id: @account.id, ids: contact_ids, cleanup: true)
  end
end
