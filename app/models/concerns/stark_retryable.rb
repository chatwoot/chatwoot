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
      content: '⚠️ Auto Reply Service Disabled: The auto reply agent has been disabled due to some issues. The conversation is now swicth to human mode and requires your attention. Please contact support if the issue persists or set the conversation back to pending mode to enable auto reply mode.',
      message_type: 'outgoing',
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      private: true
    )
  end
end
