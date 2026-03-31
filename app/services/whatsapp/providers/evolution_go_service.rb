class Whatsapp::Providers::EvolutionGoService < Whatsapp::Providers::BaseService
  def send_message(phone_number, message)
    data = if message.attachments.present?
             send_attachment_message(phone_number, message)
           else
             send_text_message(phone_number, message)
           end

    data.dig('Info', 'ID')
  rescue EvolutionGo::Client::Error => e
    handle_evolution_error(message, e)
    nil
  end

  def send_template(_phone_number, _template_info, message)
    message.update!(status: :failed, external_error: 'WhatsApp templates are not supported for Evolution Go')
    nil
  end

  def sync_templates
    whatsapp_channel.mark_message_templates_updated
  end

  def validate_provider_config?
    client.available?
  end

  def api_headers
    { 'apikey' => client.instance_token, 'Content-Type' => 'application/json' }
  end

  def media_url(media_id)
    media_id
  end

  private

  def send_text_message(phone_number, message)
    return {} if message.content.blank?

    client.send_text(
      number: phone_number,
      text: message.outgoing_content,
      quoted_message_id: quoted_message_id(message)
    )
  end

  def send_attachment_message(phone_number, message)
    attachment = message.attachments.first

    client.send_media(
      number: phone_number,
      attachment: attachment,
      caption: message.outgoing_content,
      quoted_message_id: quoted_message_id(message)
    )
  end

  def quoted_message_id(message)
    message.content_attributes['in_reply_to_external_id']
  end

  def handle_evolution_error(message, error)
    Rails.logger.error "[EVOLUTION_GO] #{error.message}"
    message.update!(status: :failed, external_error: error.message) if message.present?
  end

  def client
    @client ||= EvolutionGo::Client.new(channel: whatsapp_channel)
  end
end
