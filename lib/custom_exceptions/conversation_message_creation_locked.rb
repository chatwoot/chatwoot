# frozen_string_literal: true

class CustomExceptions::ConversationMessageCreationLocked < CustomExceptions::Base
  ERROR_CODE = 'conversation_message_creation_locked'

  def message
    if lock_state[:message_creation_lock_reason] == 'message_limit'
      "This conversation has reached the #{lock_state[:message_limit]} message limit. We will drop all messages after this limit."
    else
      'This conversation is locked. We will drop all new messages until it is unlocked.'
    end
  end

  def http_status
    :unprocessable_entity
  end

  def to_hash
    {
      error: message,
      message: message,
      error_code: ERROR_CODE,
      **lock_state
    }
  end

  private

  def lock_state
    @lock_state ||= @data.message_creation_lock_state
  end
end
