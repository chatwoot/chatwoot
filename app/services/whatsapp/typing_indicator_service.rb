class Whatsapp::TypingIndicatorService
  pattr_initialize [:conversation!]

  def perform
    return unless whatsapp_cloud_inbox?
    return if channel.reauthorization_required?

    wamid = last_inbound_whatsapp_message_id
    return if wamid.blank?

    Whatsapp::Providers::WhatsappCloudService.new(whatsapp_channel: channel).send_typing_indicator(wamid)
  end

  private

  def inbox
    conversation.inbox
  end

  def channel
    inbox.channel
  end

  def whatsapp_cloud_inbox?
    channel.is_a?(Channel::Whatsapp) && channel.provider == 'whatsapp_cloud'
  end

  def last_inbound_whatsapp_message_id
    msg = conversation.last_incoming_message
    return if msg.blank?

    msg.source_id.presence
  end
end
