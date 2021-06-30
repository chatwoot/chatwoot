class Gupshup::SendOnGupshupService < Base::SendOnChannelService
  private

  def channel_class
    Channel::Gupshup
  end

  def perform_reply
    gupshup_message = client.send(contact_inbox.source_id, message_params)
    message.update!(source_id: gupshup_message.body['messageId'])
  end

  def message_params
    params = {
      'channel': 'whatsapp',
      'message': { 'text': message.content, 'isHSM': false, 'type': 'text' }.to_json,
      'source': channel.phone_number,
      'destination': contact_inbox.source_id,
      'src.name': channel.app
    }
    params[:media_url] = attachments if message.attachments.present?
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
    Gupshup::WhatsApp.new(app=channel.app, apikey=channel.apikey, phone=channel.phone_number, version='2')
  end
end
