# frozen_string_literal: true

class ProcessSingleFollowUpJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform(follow_up_id)
    follow_up = ConversationFollowUp.find_by(id: follow_up_id)

    # Si no existe o ya no está activo, no hacer nada
    # Importante: liberar el lock si por alguna razón ya no es active
    unless follow_up&.status == 'active'
      follow_up&.update_column(:processing_started_at, nil)
      return
    end

    # Limpiar el sidekiq_job_id por compatibilidad
    follow_up.update_column(:sidekiq_job_id, nil)

    # Procesar el follow-up
    LeadRetargeting::SendFollowUpService.new(follow_up).execute

    # IMPORTANTE: Liberar siempre el lock al terminar con éxito
    follow_up.update_column(:processing_started_at, nil)

  rescue StandardError => e
    Rails.logger.error "Failed to process follow-up #{follow_up_id}: #{e.message}"
    
    if follow_up
      # Liberar el lock antes de decidir qué hacer
      follow_up.update_column(:processing_started_at, nil)
      
      handle_job_failure(follow_up, e)
    end
  end

  private

  def handle_job_failure(follow_up, error)
    follow_up.increment_retry_count!

    if follow_up.retry_count >= 3
      follow_up.mark_as_failed!("Max retries exceeded: #{error.message}")
    else
      # Reprogramar para reintento en 2 horas
      # Nota: Ahora solo cambiamos next_action_at, el Dispatcher se encargará de recogerlo
      follow_up.update!(next_action_at: 2.hours.from_now)
    end
  end
end
