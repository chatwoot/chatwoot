class ConversationFollowUp < ApplicationRecord
  belongs_to :conversation
  belongs_to :lead_follow_up_sequence
  belongs_to :sequence_enrollment, optional: true

  validates :conversation_id, uniqueness: true
  validates :status, presence: true, inclusion: { in: %w[active paused completed cancelled failed] }

  PROCESSING_TIMEOUT = 10.minutes
  REACTIVATION_DELAY = Rails.env.production? ? 30.minutes : 5.minutes

  scope :active, -> { where(status: 'active') }
  scope :pending_execution, -> { active.where('next_action_at <= ?', Time.current) }

  scope :ready_to_reactivate, lambda {
    base_conditions = where(status: 'completed')
                      .where('completed_at < ?', REACTIVATION_DELAY.ago)
                      .where(completion_reason: 'Contact replied')

    base_conditions.where(processing_started_at: nil)
                   .or(
                     base_conditions.where('processing_started_at < ?', PROCESSING_TIMEOUT.ago)
                   )
  }

  def mark_as_completed!(reason = nil)
    update!(
      status: 'completed',
      completed_at: Time.current,
      metadata: (metadata || {}).merge(
        completion_reason: reason,
        completed_at: Time.current
      )
    )
  end

  def mark_as_cancelled!(reason = nil)
    update!(
      status: 'cancelled',
      metadata: (metadata || {}).merge(
        cancellation_reason: reason,
        cancelled_at: Time.current
      )
    )
  end

  def mark_as_failed!(error_message)
    update!(
      status: 'failed',
      metadata: (metadata || {}).merge(
        failure_reason: error_message,
        failed_at: Time.current
      )
    )
  end

  def pause!
    update!(status: 'paused')
  end

  def resume!
    update!(status: 'active')
  end

  def increment_retry_count!
    current_retry = metadata&.dig('retry_count') || 0
    update!(
      metadata: (metadata || {}).merge(
        retry_count: current_retry + 1
      )
    )
  end

  def retry_count
    metadata&.dig('retry_count') || 0
  end

  def mark_processing!
    update!(processing_started_at: Time.current)
  end

  def clear_processing!
    update!(processing_started_at: nil)
  end

  def schedule_job!(execute_at = nil)
    # Refactor: Dispatcher handles scheduled jobs, but we handle immediate jobs for UX speed.

    # 1. Update the execution time in DB
    target_time = execute_at || next_action_at
    if execute_at
      update!(next_action_at: execute_at)
      target_time = execute_at
    end

    # 2. Check for immediate execution
    if target_time && target_time <= Time.current
      # Try to acquire the lock ATOMICALLY to avoid race conditions with Dispatcher
      # We only enqueue if WE successfully set processing_started_at
      locked = ConversationFollowUp.where(id: id, processing_started_at: nil)
                                   .update_all(processing_started_at: Time.current)

      if locked == 1
        Rails.logger.info "Acquired lock for immediate execution of follow-up #{id}"
        ProcessSingleFollowUpJob.perform_later(id)
      else
        Rails.logger.info "Could not acquire lock for follow-up #{id} (already processing?), skipping immediate enqueue."
      end
    else
      Rails.logger.info "Follow-up #{id} scheduled for future: #{target_time}. Dispatcher will handle it."
    end
  end

  def cancel_job!
    # Refactor: We no longer manage individual Sidekiq jobs.
    # Just clearing the ID for legacy compatibility / cleanup.
    return unless sidekiq_job_id.present?

    update_column(:sidekiq_job_id, nil)
  end
end
