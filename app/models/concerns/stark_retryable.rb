module StarkRetryable
  extend ActiveSupport::Concern

  MAX_RETRIES = 1
  RETRY_DELAY = 3

  def with_stark_retry(conversation = nil)
    retries = 0
    begin
      yield
    rescue StandardError => e
      retries += 1
      if retries <= MAX_RETRIES
        Rails.logger.warn("Stark server error encountered. Attempt #{retries} of #{MAX_RETRIES}. Retrying in #{RETRY_DELAY} seconds...")
        sleep(RETRY_DELAY)
        retry
      else
        Rails.logger.error("Stark server error persisted after #{MAX_RETRIES} retries. Handing off to human agent.")
        handle_human_handoff(conversation, e) if conversation
        nil
      end
    end
  end

  private

  def handle_human_handoff(conversation, _error)
    return unless conversation

    conversation.open!
    conversation.messages.create!(
      content: '⚠️ AI reply (Stark) disabled. The AI auto-reply has been temporarily disabled and the conversation has been assigned to a human. Feel free to reply to the user, and once done, please switch the conversation back to pending, so it can be handled by Stark: our AI agent.', # rubocop:disable Layout/LineLength
      message_type: 'outgoing',
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      private: true
    )
  end
end
