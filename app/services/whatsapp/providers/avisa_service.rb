# CUSTOMIZAÇÃO_SYNAPSEOS
# Integração direta com Avisa API (https://www.avisaapi.com.br/api).
# Substitui o modelo antigo que passava por N8N — agora Rails fala direto.
#
#   Chatwoot outgoing ──> AvisaClient ──> Avisa API ──> WhatsApp
#   WhatsApp ──> Avisa webhook ──> Chatwoot /webhooks/avisa
#
# Avisa é uma API WhatsApp não-oficial (whatsmeow). A Meta pode banir números
# que violem ToS; expor aviso claro ao cliente.
class Whatsapp::Providers::AvisaService < Whatsapp::Providers::BaseService
  def send_message(phone_number, message)
    @message = message
    if message.attachments.present?
      # v1 só-texto: attachment support vem no PR seguinte.
      Rails.logger.warn("[AVISA] anexos ainda não suportados (msg #{message.id})")
      nil
    else
      send_text_message(phone_number, message)
    end
  end

  # Avisa/whatsmeow não suporta templates HSM. Degradamos pra texto.
  def send_template(phone_number, _template_info, message)
    Rails.logger.warn('[AVISA] send_template não suportado em API não-oficial; enviando texto plano')
    send_text_message(phone_number, message)
  end

  def sync_templates
    whatsapp_channel.mark_message_templates_updated
  end

  def validate_provider_config?
    whatsapp_channel.provider_config['api_key'].to_s.strip.present?
  end

  # Mídia inbound vem como upload do multipart; URL interna do ActiveStorage.
  def media_url(media_id)
    media_id
  end

  private

  def client
    @client ||= Whatsapp::Providers::AvisaClient.new(
      api_key: whatsapp_channel.provider_config['api_key'],
      base_url: whatsapp_channel.provider_config['base_url']
    )
  end

  def send_text_message(phone_number, message)
    result = client.send_text(number: phone_number, message: message.content.to_s)
    result[:id]
  rescue Whatsapp::Providers::AvisaClient::Error => e
    Rails.logger.error("[AVISA] envio falhou: #{e.message}")
    nil
  end
end
