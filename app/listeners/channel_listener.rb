class ChannelListener < BaseListener
  def conversation_typing_on(event)
    handle_typing_event(event)
  end

  def conversation_recording(event)
    handle_typing_event(event)
  end

  def conversation_typing_off(event)
    handle_typing_event(event)
  end

  private

  def handle_typing_event(event)
    is_private, conversation = event.data.values_at(:is_private, :conversation)
    return if is_private

    channel = conversation.inbox.channel
    return unless channel.respond_to?(:toggle_typing_status)

    channel.toggle_typing_status(event.name, conversation: conversation)
  end
end
