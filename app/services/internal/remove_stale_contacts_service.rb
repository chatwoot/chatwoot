class Internal::RemoveStaleContactsService
  pattr_initialize [:account!]

  def perform(batch_size = 1000)
    contacts_to_remove = @account.contacts.stale_without_conversations(30.days.ago)
    total_deleted = 0

    contacts_to_remove.find_in_batches(batch_size: batch_size) do |batch|
      contact_ids = batch.map(&:id)
      Contact.where(id: contact_ids).destroy_all
      total_deleted += batch.size
      Rails.logger.info "Deleted #{batch.size} contacts (#{total_deleted} total) for account #{@account.id}"
    end
  end
end
