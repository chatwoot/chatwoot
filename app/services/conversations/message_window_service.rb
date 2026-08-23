class Conversations::MessageWindowService
  def initialize(conversation)
    @conversation = conversation
  end

  def can_reply?
    return true if messaging_window.blank?

    last_message_in_messaging_window?(messaging_window)
  end

  private

  def messaging_window
    @conversation.inbox.channel.messaging_window
  end

  def last_message_in_messaging_window?(time)
    return false if last_incoming_message.nil?

    Time.current < last_incoming_message.created_at + time
  end

  def last_incoming_message
    @last_incoming_message ||= @conversation.messages.where(account_id: @conversation.account_id).incoming&.last
  end
end
