class Internal::RemoveStaleContactsService
  def perform
    return unless remove_stale_contacts_job_enabled?

    time_period = 30.days.ago
    contacts_to_delete = stale_contacts(time_period)

    log_stale_contacts_deletion(contacts_to_delete, time_period)

    # Since the number of records to delete is very high,
    # delete_all would be faster than destroy_all since it operates at database level
    # and avoid loading all the records in memory
    # Transaction and batching is used to avoid deadlock and memory issues
    Contact.transaction do
      contacts_to_delete
        .find_in_batches(batch_size: 10_000) do |group|
          Contact.where(id: group.map(&:id)).delete_all
        end
    end
  end

  private

  def remove_stale_contacts_job_enabled?
    job_status = ENV.fetch('REMOVE_STALE_CONTACTS_JOB_STATUS', false)
    return false unless ActiveModel::Type::Boolean.new.cast(job_status)

    true
  end

  def stale_contacts(time_period)
    Contact.stale_without_conversations(time_period)
  end

  def log_stale_contacts_deletion(contacts, time_period)
    count = contacts.count
    Rails.logger.info "Deleting #{count} stale contacts older than #{time_period}"

    # Log the SQL query without executing it
    sql_query = contacts.to_sql
    Rails.logger.info("SQL Query: #{sql_query}")
  end
end
