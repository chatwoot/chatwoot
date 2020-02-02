class Twitter::SendReplyService
  pattr_initialize [:message!]

  def perform
    return if message.private
    return if inbox.channel.class.to_s != 'Channel::TwitterProfile'
    return unless outgoing_message_from_chatwoot?

    $twitter.send_direct_message(
      recipient_id: contact_inbox.source_id,
      message: message.content
    )
  end

  private

  def outgoing_message_from_chatwoot?
    message.outgoing?
  end

  delegate :contact_inbox, to: :conversation
  delegate :conversation, to: :message
  delegate :inbox, to: :conversation
end
