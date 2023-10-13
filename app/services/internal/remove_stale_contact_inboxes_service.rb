class Internal::RemoveStaleContactInboxesService
  def perform
    ninety_days_ago = 90.days.ago
    # time_period = ENV.fetch('STALE_CONTACT_INBOX_TIME_PERIOD', ninety_days_ago)
    time_period = ninety_days_ago
    contact_inboxes_to_delete = ContactInbox.left_joins(:conversations)
                                            .where('contact_inboxes.created_at < ?', time_period)
                                            .where(conversations: { contact_id: nil })

    Rails.logger.info "Deleting #{contact_inboxes_to_delete.count} stale contact inboxes older than #{time_period}"

    # Log the SQL query without executing it
    sql_query = contact_inboxes_to_delete.to_sql
    Rails.logger.info("SQL Query: #{sql_query}")

    # commenting out the delete for now
    # since the number of record is very high, delete_all would be faster
    # contact_inboxes_to_delete.destroy_all
    contact_inboxes_to_delete.delete_all
  end
end
