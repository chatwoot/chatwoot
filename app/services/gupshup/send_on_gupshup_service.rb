class Gupshup::SendOnGupshupService < Base::SendOnChannelService
  private

  def channel_class
    Channel::Gupshup
  end

  def perform_reply
    gupshup_message = client.send(contact_inbox.source_id, message_params)
    message.update!(source_id: gupshup_message.body[:messageId])

  end
  def message_params
    # Only text messages payload added. Yet to add other attachments
    payload = {
      'isHSM': false,
      'type': 'text',
      'text': message.content,
    }
    payload[:media_url] = attachments if message.attachments.present?
    payload
  end

  def attachments
    message.attachments.map(&:file_url)
  end

  def inbox
    @inbox ||= message.inbox
  end

  def channel
    @channel ||= inbox.channel
  end

  def outgoing_message?
    message.outgoing? || message.template?
  end

  def client
    Gupshup::REST::OutboundMessage.new(app=channel.app, apikey=channel.apikey, phone=channel.phone_number, version='2')
  end
end
