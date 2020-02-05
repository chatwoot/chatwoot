class Twitter::SendReplyService
  pattr_initialize [:message!]

  def perform
    return if message.private
    return if message.fb_id
    return if inbox.channel.class.to_s != 'Channel::TwitterProfile'
    return unless outgoing_message_from_chatwoot?

    send_reply
  end

  private

  def conversation_type
    conversation.additional_attributes['type']
  end

  def send_direct_message
    $twitter.send_direct_message(
      recipient_id: contact_inbox.source_id,
      message: message.content
    )
  end

  def send_tweet_reply
    $twitter.send_tweet_reply(
      reply_to_tweet_id: conversation.additional_attributes['tweet_id'],
      tweet: message.content
    )
  end

  def send_reply
    conversation_type == 'tweet' ? send_tweet_reply : send_direct_message
  end

  def outgoing_message_from_chatwoot?
    message.outgoing?
  end

  delegate :contact_inbox, to: :conversation
  delegate :conversation, to: :message
  delegate :inbox, to: :conversation
end
