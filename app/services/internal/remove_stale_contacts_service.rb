class Internal::RemoveStaleContactsService
  pattr_initialize [:account!]

  def perform
    contacts_to_remove = @account.contacts.stale_without_conversations(30.days.ago)

    count = contacts_to_remove.count
    Rails.logger.info "Removing #{count} stale contacts for account #{@account.id}"

    # Process in batches to handle large datasets
    contacts_to_remove.find_in_batches(batch_size: 10_000) do |batch|
      contact_ids = batch.map(&:id)
      Contact.where(id: contact_ids).destroy_all
    end
  end
end
