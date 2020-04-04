class Twilio::OutgoingMessageService
  pattr_initialize [:content!]

  def perform
    return if message.private
    return if message.source_id
    return if inbox.channel.class.to_s != 'Channel::TwilioSms'
    return unless message.outgoing?

    twilio_message = client.messages.create(
      body: content,
      from: channel.phone_number,
      to: message.contact.phone_number
    )
    message.update!(source_id: twilio_message.sid)
  end

  private

  def inbox
    @inbox ||= message.inbox
  end

  def channel
    @channel ||= inbox.channel
  end

  def client
    ::Twilio::REST::Client.new(channel.account_sid, channel.auth_token)
  end
end
