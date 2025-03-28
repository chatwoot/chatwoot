class Internal::RemoveStaleContactsService
  pattr_initialize [:account!]

  def perform(batch_size = 1000)
    contacts_to_remove = @account.contacts.stale_without_conversations(30.days.ago)
    total_deleted = 0

    Rails.logger.info "[Internal::RemoveStaleContactsService] Starting removal of stale contacts for account #{@account.id}"

    contacts_to_remove.find_in_batches(batch_size: batch_size) do |batch|
      contact_ids = batch.map(&:id)

      ContactInbox.where(contact_id: contact_ids).delete_all
      Contact.where(id: contact_ids).delete_all
      total_deleted += batch.size
      Rails.logger.info "[Internal::RemoveStaleContactsService] Deleted #{batch.size} contacts (#{total_deleted} total) for account #{@account.id}"
    end
  end
end
