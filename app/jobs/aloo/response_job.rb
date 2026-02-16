# frozen_string_literal: true

class Aloo::ResponseJob < ApplicationJob
  queue_as :default
  retry_on RubyLLM::Error, wait: :polynomially_longer, attempts: 3

  def perform(conversation_id, message_id)
    conversation = Conversation.find_by(id: conversation_id)
    message = Message.find_by(id: message_id)

    return unless conversation && message

    # Cross-system dedup: only one AI system handles each message
    dedup_key = message.source_id.presence || "msg_#{message.id}"
    redis_key = "ai_response_lock:#{dedup_key}"
    lock_acquired = Redis::Alfred.set(redis_key, 'aloo_local', nx: true, ex: 300)

    unless lock_acquired
      Rails.logger.info "[Aloo::ResponseJob] Another AI system already handling message #{message.id}, skipping"
      return
    end

    Aloo::ResponseService.new(conversation, message).call
  rescue StandardError => e
    Rails.logger.error("[Aloo::ResponseJob] Error: #{e.message}")
    Rails.logger.error(e.backtrace.first(5).join("\n"))
    raise
  ensure
    # Clean up lock if we acquired it
    if redis_key && lock_acquired
      Redis::Alfred.delete(redis_key)
      Rails.logger.info "[Aloo::ResponseJob] Cleaned up lock for message #{message_id}"
    end
  end
end
