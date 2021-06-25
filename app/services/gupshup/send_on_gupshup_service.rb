class Gupshup::SendOnGupshupService < Base::SendOnChannelService
  private

  def channel_class
    Channel::Gupshup
  end

  def perform_reply
    gupshup_message = client.send(message_params)
    message.update!(source_id: gupshup_message.sid)
  end

  def message_params
    params = {
      body: message.content,
      from: channel.phone_number,
      to: contact_inbox.source_id
    }
    params[:media_url] = attachments if channel.whatsapp? && message.attachments.present?
    params
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
    ::Gupshup::REST::OutboundMessage.new(app=channel.app, apikey=channel.apikey, version=channel.version, phone=channel.phone)
  end
end
