# Cleanup job that runs periodically to catch orphaned follow-ups
# that should have been scheduled but weren't (edge case handling)
class ProcessLeadFollowUpsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    # Find active follow-ups without a scheduled job
    orphaned_follow_ups = ConversationFollowUp
                          .active
                          .where(sidekiq_job_id: nil)
                          .where('next_action_at <= ?', Time.current)

    orphaned_count = 0

    orphaned_follow_ups.find_each(batch_size: 100) do |follow_up|
      # Schedule the job immediately since it's already past due
      follow_up.schedule_job!
      orphaned_count += 1
      Rails.logger.info "Rescheduled orphaned follow-up #{follow_up.id}"
    rescue StandardError => e
      Rails.logger.error "Failed to reschedule orphaned follow-up #{follow_up.id}: #{e.message}"
    end

    Rails.logger.info "Cleanup job completed: rescheduled #{orphaned_count} orphaned follow-ups" if orphaned_count.positive?
  end
end
