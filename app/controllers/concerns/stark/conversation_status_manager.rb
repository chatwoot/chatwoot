module Stark
  module ConversationStatusManager
    extend ActiveSupport::Concern

    def update_conversation_status(status, force: false)
      return true if current_conversation.status == status.to_s
      return false unless force || current_conversation.open?
      current_conversation.update!(status: status)
    end

    def mark_conversation_open
      update_conversation_status(:open, force: true)
    end

    def mark_conversation_pending
      update_conversation_status(:pending) if current_conversation.open?
    end
  end
end
