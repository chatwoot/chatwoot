# CUSTOMIZAÇÃO_SYNAPSEOS
# Integração com Avisa API via N8N (mesmo padrão do Hyperflow).
#
# Avisa é uma API WhatsApp não-oficial (whatsmeow/Baileys-like). A Meta
# pode banir números que violem ToS; expor aviso claro ao cliente.
#
#   Chatwoot outgoing ──POST──> N8N webhook ──> Avisa API ──> WhatsApp
#   WhatsApp ──> Avisa webhook ──> N8N ──POST──> Chatwoot /webhooks/avisa/:phone_number
#
# Esta classe é o lado de saída: faz POST no n8n_outgoing_url configurado
# com um payload plano que o flow N8N mapeia pra API Avisa.
class Whatsapp::Providers::AvisaService < Whatsapp::Providers::BaseService
  def send_message(phone_number, message)
    @message = message
    if message.attachments.present?
      send_attachment_message(phone_number, message)
    else
      send_text_message(phone_number, message)
    end
  end

  # Avisa/whatsmeow não suportam templates HSM (não-oficial). Degradamos pra texto.
  def send_template(phone_number, _template_info, message)
    Rails.logger.warn('[AVISA] send_template não suportado em API não-oficial; enviando texto plano')
    send_text_message(phone_number, message)
  end

  def sync_templates
    # Não existem templates aprovados pela Meta no fluxo não-oficial.
    whatsapp_channel.mark_message_templates_updated
  end

  def validate_provider_config?
    whatsapp_channel.provider_config['n8n_outgoing_url'].to_s =~ %r{\Ahttps?://.+}
  end

  def api_headers
    headers = { 'Content-Type' => 'application/json' }
    secret = whatsapp_channel.provider_config['webhook_secret']
    headers['X-Synapseos-Signature'] = secret if secret.present?
    headers
  end

  # N8N entrega URLs públicas/pré-assinadas para as mídias.
  def media_url(media_id)
    media_id
  end

  private

  def send_text_message(phone_number, message)
    post_to_n8n(
      message: message,
      body: { to: phone_number, type: 'text', payload: { text: message.content.to_s } }
    )
  end

  def send_attachment_message(phone_number, message)
    attachment = message.attachments.first
    post_to_n8n(
      message: message,
      body: {
        to: phone_number,
        type: attachment_type_for(attachment),
        payload: { url: attachment.download_url, caption: message.content.to_s }
      }
    )
  end

  def attachment_type_for(attachment)
    case attachment.file_type
    when 'image' then 'image'
    when 'audio' then 'audio'
    when 'video' then 'video'
    else 'document'
    end
  end

  def post_to_n8n(message:, body:)
    url = whatsapp_channel.provider_config['n8n_outgoing_url']
    if url.blank?
      Rails.logger.warn("[AVISA] n8n_outgoing_url não configurado no channel #{whatsapp_channel.id}")
      return nil
    end

    payload = body.merge(
      chatwoot_message_id: message.id,
      chatwoot_conversation_id: message.conversation_id,
      chatwoot_inbox_id: message.inbox_id
    )
    response = HTTParty.post(url, headers: api_headers, body: payload.to_json, timeout: 30)
    process_response(response, message)
  rescue StandardError => e
    Rails.logger.error("[AVISA] POST para N8N falhou: #{e.class}: #{e.message}")
    nil
  end
end
