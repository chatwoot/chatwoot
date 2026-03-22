class Conversations::DetectAbandonedJob < ApplicationJob
  queue_as :scheduled_jobs

  ABANDONMENT_THRESHOLD = 90.minutes

  def perform
    abandoned_ids = abandonment_candidates.pluck(:id)
    return if abandoned_ids.empty?

    Conversation.where(id: abandoned_ids).update_all('abandoned_at = waiting_since') # rubocop:disable Rails/SkipsModelValidations
  end

  private

  def abandonment_candidates
    threshold = ABANDONMENT_THRESHOLD.ago

    Conversation
      .where(status: :open)
      .where('waiting_since < ?', threshold)
      .where(abandoned_at: nil)
      .where.not(waiting_since: nil)
      .where(
        <<~SQL.squish
          NOT EXISTS (
            SELECT 1 FROM messages m
            WHERE m.conversation_id = conversations.id
              AND m.message_type = #{Message.message_types[:outgoing]}
              AND m.created_at > conversations.waiting_since
          )
        SQL
      )
  end
end
