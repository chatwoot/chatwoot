class WhatsappTypingListener < BaseListener
  def conversation_typing_on(event)
    return unless should_send_whatsapp_typing?(event)

    WhatsappTypingJob.perform_later(
      event.data[:conversation].id,
      event.data[:user].id
    )
  end

  private

  def should_send_whatsapp_typing?(event)
    conversation = event.data[:conversation]
    user = event.data[:user]

    # Only for agents (not contacts)
    return false if user.is_a?(Contact)

    # Only for WhatsApp Cloud inboxes
    inbox = conversation.inbox
    return false unless inbox.channel_type == 'Channel::Whatsapp'
    return false unless inbox.channel.provider == 'whatsapp_cloud'

    # Don't send for private notes
    return false if event.data[:is_private]

    true
  end
end
