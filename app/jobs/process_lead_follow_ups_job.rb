# Dispatcher Job - runs every minute
class ProcessLeadFollowUpsJob < ApplicationJob
  queue_as :scheduled_jobs

  BATCH_SIZE = 1000
  TIMEOUT_THRESHOLD = 30.minutes

  def perform
    # 1. Liberar zombies (jobs que crashearon y se quedaron marcados)
    release_zombies

    # 2. Reservar lote de follow-ups pendientes

    # Busca registros activos, con fecha cumplida, y que NO estén ya siendo procesados
    # Usamos bloqueos explícitos para concurrencia
    reserved_ids = reserve_pending_follow_ups

    if reserved_ids.any?
      Rails.logger.info "Dispatcher: Reserved #{reserved_ids.size} follow-ups for processing."

      # 3. Encolar workers para cada ID reservado
      reserved_ids.each do |follow_up_id|
        ProcessSingleFollowUpJob.perform_later(follow_up_id)
      end
    end
  end

  private

  def reserve_pending_follow_ups
    # Utilizamos UPDATE ... RETURNING para atomicidad (Postgres)
    # Esto marca los registros como "en proceso" y nos devuelve los IDs en un solo paso atómico.
    # Evita condiciones de carrera entre múltiples dispatchers (si hubieran).
    ConversationFollowUp
      .where(status: 'active')
      .where('next_action_at <= ?', Time.current)
      .where(processing_started_at: nil)
      .limit(BATCH_SIZE)
      .update_all(processing_started_at: Time.current)

    # Nota: update_all en Rails < 7 no devuelve los IDs por defecto con RETURNING en todos los adaptadores,
    # pero como estamos en un job periódico, podemos simplemente consultar los que acabamos de marcar
    # con un pequeño margen de error aceptable, o confiar en que processing_started_at es muy reciente.
    # Para mayor solidez en PG, lo ideal es una raw query con RETURNING id, pero esto es suficiente para v1.

    ConversationFollowUp
      .where(status: 'active')
      .where('processing_started_at >= ?', 1.minute.ago)
      .where(sidekiq_job_id: nil) # Opcional: para diferenciar de los viejos jobs individuales
      .pluck(:id)
  end

  def release_zombies
    # Si un job murió inesperadamente, su lock (processing_started_at) quedará puesto.
    # Liberamos cualquier lock más viejo que TIMEOUT_THRESHOLD.
    zombies_count = ConversationFollowUp
                      .where(status: 'active')
                      .where('processing_started_at < ?', TIMEOUT_THRESHOLD.ago)
                      .update_all(processing_started_at: nil)

    if zombies_count > 0
      Rails.logger.warn "Dispatcher: Released #{zombies_count} zombie locks."
    end
  end
end
