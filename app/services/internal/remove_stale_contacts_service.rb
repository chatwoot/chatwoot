class Internal::RemoveStaleContactsService
  pattr_initialize [:account!]

  def perform(batch_size = 1000)
    contacts_to_remove = @account.contacts.stale_without_conversations(30.days.ago)

    contacts_to_remove.find_in_batches(batch_size: batch_size) do |batch|
      Rails.logger.info "Removing #{batch.size} stale contacts for account #{@account.id}"
      contact_ids = batch.map(&:id)
      Contact.where(id: contact_ids).destroy_all
    end
  end
end
