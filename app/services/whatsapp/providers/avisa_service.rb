# CUSTOMIZAÇÃO_SYNAPSEOS
# Integração com a Avisa API (WhatsApp não-oficial, estilo Baileys).
# APIs não-oficiais mudam com frequência; os pontos `TODO_AVISA`
# precisam ser confirmados contra a doc atual antes de ir pra produção.
# RISCO: contas podem ser banidas pela Meta. Exibir aviso ao cliente na UI.
class Whatsapp::Providers::AvisaService < Whatsapp::Providers::BaseService
  DEFAULT_API_HOST = 'https://api.avisaapi.com.br'.freeze

  def send_message(phone_number, message)
    @message = message

    if message.attachments.present?
      send_attachment_message(phone_number, message)
    else
      send_text_message(phone_number, message)
    end
  end

  # APIs Baileys-like geralmente não trabalham com templates aprovados pela Meta.
  # Caso a Avisa ofereça algo equivalente, implementar aqui.
  def send_template(phone_number, _template_info, message)
    Rails.logger.warn('[AVISA] send_template não é suportado em APIs não-oficiais; enviando texto simples')
    send_text_message(phone_number, message)
  end

  def sync_templates
    # Sem templates aprovados no fluxo não-oficial.
    whatsapp_channel.mark_message_templates_updated
  end

  def validate_provider_config?
    response = HTTParty.get("#{api_base_path}/health", headers: api_headers)
    response.success?
  rescue StandardError => e
    Rails.logger.warn("[AVISA] validate_provider_config? falhou: #{e.message}")
    false
  end

  def api_headers
    {
      'Authorization' => "Bearer #{whatsapp_channel.provider_config['token']}",
      'Content-Type' => 'application/json'
    }
  end

  def media_url(media_id)
    "#{api_base_path}/media/#{media_id}"
  end

  private

  def api_base_path
    whatsapp_channel.provider_config['api_base_url'].presence || DEFAULT_API_HOST
  end

  # TODO_AVISA: confirmar formato do payload (/send-message? /messages?).
  def send_text_message(phone_number, message)
    response = HTTParty.post(
      "#{api_base_path}/send-message",
      headers: api_headers,
      body: { phone: phone_number, message: message.content }.to_json
    )
    process_response(response, message)
  end

  # TODO_AVISA: implementar envio de mídia (áudio, imagem, documento).
  def send_attachment_message(phone_number, message)
    Rails.logger.warn("[AVISA] send_attachment_message not implemented yet — message=#{message.id}")
    send_text_message(phone_number, message)
  end
end
