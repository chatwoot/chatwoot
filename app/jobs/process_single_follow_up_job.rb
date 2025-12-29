# frozen_string_literal: true

class ProcessSingleFollowUpJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform(follow_up_id)
    follow_up = ConversationFollowUp.find_by(id: follow_up_id)

    # Si no existe o ya no está activo, no hacer nada
    return unless follow_up&.status == 'active'

    # Limpiar el sidekiq_job_id ya que este job ya se está ejecutando
    follow_up.update_column(:sidekiq_job_id, nil)

    # Procesar el follow-up
    LeadRetargeting::SendFollowUpService.new(follow_up).execute
  rescue StandardError => e
    Rails.logger.error "Failed to process follow-up #{follow_up_id}: #{e.message}"
    Rails.logger.error e.backtrace.first(10).join("\n")

    # Si hay error, incrementar retry count y manejar
    if follow_up
      follow_up.increment_retry_count!

      if follow_up.retry_count >= 3
        follow_up.mark_as_failed!("Max retries exceeded: #{e.message}")
      else
        # Reprogramar para reintento en 2 horas
        follow_up.schedule_job!(2.hours.from_now)
      end
    end
  end
end
