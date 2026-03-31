class ProcessReengagementsJob < ApplicationJob
  queue_as :scheduled_jobs

  BATCH_SIZE = 500
  ZOMBIE_TIMEOUT = ConversationReengagement::PROCESSING_TIMEOUT

  def perform
    release_zombies
    ids = reserve_pending

    return if ids.empty?

    Rails.logger.info "ProcessReengagementsJob: reserved #{ids.size} reengagements"
    ids.each { |id| ProcessSingleReengagementJob.perform_later(id) }
  end

  private

  def reserve_pending
    ConversationReengagement
      .where(status: 'active')
      .where('next_fire_at <= ?', Time.current)
      .where(processing_started_at: nil)
      .limit(BATCH_SIZE)
      .update_all(processing_started_at: Time.current)

    ConversationReengagement
      .where(status: 'active')
      .where('processing_started_at >= ?', 1.minute.ago)
      .pluck(:id)
  end

  def release_zombies
    count = ConversationReengagement
              .where(status: 'active')
              .where('processing_started_at < ?', ZOMBIE_TIMEOUT.ago)
              .update_all(processing_started_at: nil)

    Rails.logger.warn "ProcessReengagementsJob: released #{count} zombie locks" if count > 0
  end
end
