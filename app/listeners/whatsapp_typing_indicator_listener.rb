class WhatsappTypingIndicatorListener < BaseListener
  include Events::Types

  def conversation_typing_on(event)
    return if event.data[:is_private]

    user = event.data[:user]
    return unless user.is_a?(User)

    conversation = event.data[:conversation]
    Whatsapp::TypingIndicatorJob.perform_later(conversation.id)
  end
end
