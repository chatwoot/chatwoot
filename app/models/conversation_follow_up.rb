class ConversationFollowUp < ApplicationRecord
  belongs_to :conversation
  belongs_to :lead_follow_up_sequence

  validates :conversation_id, uniqueness: true
  validates :status, presence: true, inclusion: { in: %w[active paused completed cancelled failed] }

  PROCESSING_TIMEOUT = 10.minutes
  REACTIVATION_DELAY = Rails.env.production? ? 30.minutes : 5.minutes

  scope :active, -> { where(status: 'active') }
  scope :pending_execution, -> { active.where('next_action_at <= ?', Time.current) }

  scope :ready_to_reactivate, lambda {
    base_conditions = where(status: 'completed')
                      .where('completed_at < ?', REACTIVATION_DELAY.ago)
                      .where("metadata->>'completion_reason' = ?", 'Contact replied')

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
    # Cancelar job anterior si existe
    cancel_job!

    # Usar next_action_at si no se especifica tiempo
    execute_at ||= next_action_at

    return unless execute_at

    # Si el tiempo es presente o pasado, ejecutar inmediatamente
    if execute_at <= Time.current
      job = ProcessSingleFollowUpJob.perform_later(id)
      update_column(:sidekiq_job_id, job.provider_job_id) if job.provider_job_id
      Rails.logger.info "Queued immediate job for follow-up #{id}"
    else
      # Si es futuro, programar para ese tiempo
      job = ProcessSingleFollowUpJob.set(wait_until: execute_at).perform_later(id)
      update_column(:sidekiq_job_id, job.provider_job_id)
      Rails.logger.info "Scheduled job #{job.provider_job_id} for follow-up #{id} at #{execute_at}"
    end
  end

  def cancel_job!
    return unless sidekiq_job_id.present?

    # Buscar y eliminar el job programado de Sidekiq
    scheduled_set = Sidekiq::ScheduledSet.new
    job = scheduled_set.find_job(sidekiq_job_id)
    job&.delete

    Rails.logger.info "Cancelled job #{sidekiq_job_id} for follow-up #{id}"

    update_column(:sidekiq_job_id, nil)
  rescue StandardError => e
    Rails.logger.error "Failed to cancel job #{sidekiq_job_id}: #{e.message}"
    # Limpiar el ID de todos modos ya que el job probablemente ya no existe
    update_column(:sidekiq_job_id, nil)
  end
end
