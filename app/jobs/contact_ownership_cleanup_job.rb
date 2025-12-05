class ContactOwnershipCleanupJob < ApplicationJob
  queue_as :low

  def perform
    # Process each account with the feature enabled
    Account.where("custom_attributes->>'enable_timed_contact_ownership' = 'true'").find_each do |account|
      duration_minutes = account.contact_ownership_duration_minutes
      next if duration_minutes.zero?

      cleanup_expired_contacts(account, duration_minutes)
    end
  end

  private

  def cleanup_expired_contacts(account, duration_minutes)
    cutoff_time = Time.current - duration_minutes.minutes

    # Use raw SQL for better performance on bulk updates
    # We intentionally skip validations here since we're only clearing fields
    # rubocop:disable Rails/SkipsModelValidations
    expired_count = account.contacts
                           .where.not(assignee_id: nil)
                           .where("(custom_attributes->>'last_resolved_at')::timestamp < ?", cutoff_time)
                           .update_all(
                             assignee_id: nil,
                             custom_attributes: Arel.sql("custom_attributes - 'last_resolved_at'")
                           )
    # rubocop:enable Rails/SkipsModelValidations

    Rails.logger.info "Cleared #{expired_count} expired contact assignments for account #{account.id}" if expired_count.positive?
  rescue StandardError => e
    Rails.logger.error "Error cleaning up contact ownership for account #{account.id}: #{e.message}"
    Sentry.capture_exception(e) if defined?(Sentry)
  end
end
