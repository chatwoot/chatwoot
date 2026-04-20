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
    # FOR UPDATE SKIP LOCKED: reserva atómica en una sola operación, sin race condition.
    # Cualquier dispatcher concurrente simplemente saltea las filas ya reservadas.
    sql = <<~SQL.squish
      UPDATE conversation_follow_ups
      SET processing_started_at = NOW()
      WHERE id IN (
        SELECT id FROM conversation_follow_ups
        WHERE status = 'active'
          AND next_action_at <= NOW()
          AND processing_started_at IS NULL
        ORDER BY next_action_at ASC
        LIMIT #{BATCH_SIZE}
        FOR UPDATE SKIP LOCKED
      )
      RETURNING id
    SQL

    ActiveRecord::Base.connection.select_values(sql).map(&:to_i)
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
