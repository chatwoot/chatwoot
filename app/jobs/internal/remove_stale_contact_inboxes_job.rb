# housekeeping
# remove contact inboxes that does not have any conversations
# and are older than 3 months

class Internal::RemoveStaleContactInboxesJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    ninety_days_ago = 90.days.ago
    contact_inboxes_to_delete = ContactInbox.left_joins(:conversations)
                                            .where('contact_inboxes.created_at < ?', ninety_days_ago)
                                            .where(conversations: { contact_id: nil })

    Rails.logger.info "Deleting #{contact_inboxes_to_delete.count} stale contact inboxes"

    # Log the SQL query without executing it
    sql_query = contact_inboxes_to_delete.to_sql
    Rails.logger.info("SQL Query: #{sql_query}")

    # commenting out the delete for now
    # contact_inboxes_to_delete.destroy_all
  end
end
