module ConversationPinHelpers
  extend ActiveSupport::Concern

  included do
    belongs_to :pinned_message, class_name: 'Message', optional: true
  end

  def pin_message!(message)
    # Ensure the message belongs to the conversation
    if message.conversation_id != id
      raise StandardError, 'Message does not belong to this conversation'
    end

    update!(pinned_message_id: message.id)
  end

  def unpin_message!
    update!(pinned_message_id: nil)
  end

  def message_pinned?
    pinned_message_id.present?
  end
end
