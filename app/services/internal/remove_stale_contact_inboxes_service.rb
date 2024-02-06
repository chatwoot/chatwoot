class Internal::RemoveStaleContactInboxesService
  def perform
    return unless remove_stale_contact_inbox_job_enabled?

    time_period = 90.days.ago
    contact_inboxes_to_delete = stale_contact_inboxes(time_period)

    log_stale_contact_inboxes_deletion(contact_inboxes_to_delete, time_period)

    # Since the number of records to delete is very high,
    # delete_all would be faster than destroy_all since it operates at database level
    # and avoid loading all the records in memory
    # Transaction and batching is used to avoid deadlock and memory issues
    ContactInbox.transaction do
      contact_inboxes_to_delete
        .find_in_batches(batch_size: 10_000) do |group|
          ContactInbox.where(id: group.map(&:id)).delete_all
        end
    end
  end

  private

  def remove_stale_contact_inbox_job_enabled?
    job_status = ENV.fetch('REMOVE_STALE_CONTACT_INBOX_JOB_STATUS', false)
    return false unless ActiveModel::Type::Boolean.new.cast(job_status)

    true
  end

  def stale_contact_inboxes(time_period)
    ContactInbox.stale_without_conversations(time_period)
  end

  def log_stale_contact_inboxes_deletion(contact_inboxes, time_period)
    count = contact_inboxes.count
    Rails.logger.info "Deleting #{count} stale contact inboxes older than #{time_period}"

    # Log the SQL query without executing it
    sql_query = contact_inboxes.to_sql
    Rails.logger.info("SQL Query: #{sql_query}")
  end
end
