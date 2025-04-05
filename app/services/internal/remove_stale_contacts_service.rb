class Internal::RemoveStaleContactsService
  pattr_initialize [:account!]

  def perform(batch_size = 1000)
    Rails.logger.info "[Internal::RemoveStaleContactsService] Starting removal of stale contacts for account #{@account.id}"

    stale_contacts = @account.contacts.stale_without_conversations(30.days.ago)
    total_deleted = 0

    # Get only IDs in batches without loading full records
    stale_contacts.select(:id).in_batches(of: batch_size) do |relation|
      contact_ids = relation.pluck(:id)
      next if contact_ids.empty?

      ContactInbox.where(contact_id: contact_ids).delete_all
      Contact.where(id: contact_ids).delete_all

      total_deleted += contact_ids.size
      Rails.logger.info "[Internal::RemoveStaleContactsService] Deleted #{contact_ids.size} contacts " \
                        "(#{total_deleted} total) for account #{@account.id}"
    end

    Rails.logger.info "[Internal::RemoveStaleContactsService] Completed removal of #{total_deleted} stale contacts " \
                      "for account #{@account.id}"
  end

  # Process stale contacts across all accounts
  def perform_global(batch_size = 1000)
    Rails.logger.info '[Internal::RemoveStaleContactsService] Starting global removal of stale contacts'

    stale_contacts = Contact.stale_without_conversations(30.days.ago)
    total_deleted = 0

    stale_contacts.select(:id).in_batches(of: batch_size) do |relation|
      contact_ids = relation.pluck(:id)
      next if contact_ids.empty?

      ContactInbox.where(contact_id: contact_ids).delete_all
      Contact.where(id: contact_ids).delete_all

      total_deleted += contact_ids.size
      Rails.logger.info "[Internal::RemoveStaleContactsService] Deleted #{contact_ids.size} contacts " \
                        "(#{total_deleted} total)"
    end

    Rails.logger.info "[Internal::RemoveStaleContactsService] Completed global removal of #{total_deleted} stale contacts"
  end
end
