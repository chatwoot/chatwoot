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
      send_attachment_message(phone_number, message)
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
    id = result[:id]
    # Avisa respondeu 2xx mas SEM Id da mensagem: a sessão WhatsApp do canal está
    # desconectada (ou o número é inválido) — a Avisa aceita o request mas não cria
    # a mensagem. Sem marcar failed, a msg fica "sent + source_id null" = relógio
    # ETERNO no UI (nunca falha, nunca alerta). Espelha o path de mídia (que já
    # marca failed). Repro: 26/06→30/06, sessão Avisa do inbox 2 caída, 100% das
    # outgoing com source_id null.
    return mark_send_failed(message, 'envio não confirmado (sem Id — sessão WhatsApp pode estar desconectada)') if id.blank?

    id
  rescue Whatsapp::Providers::AvisaClient::Error => e
    Rails.logger.error("[AVISA] envio falhou: #{e.message}")
    mark_send_failed(message, e.message)
  end

  # Marca a mensagem como falha (status + external_error visível no UI) e retorna
  # nil pro caller. Fonte única do tratamento de falha de envio de texto.
  def mark_send_failed(message, reason)
    message.update!(status: :failed, external_error: "Avisa: #{reason}")
    nil
  end

  # Envia anexo via endpoint base64 (sendImage/sendDocument/sendAudio) quando
  # possível — dispensa URL pública e funciona mesmo com storage local do
  # Railway. Video ainda depende de `sendMedia` com URL pública (requer S3/R2).
  #
  # ActiveStorage::FileNotFoundError acontece quando web e worker rodam em
  # containers separados com storage local: o worker nao enxerga o arquivo
  # gravado pelo web. Marcamos a mensagem como failed e retornamos nil pra
  # impedir o retry loop infinito do Sidekiq.
  def send_attachment_message(phone_number, message)
    attachment = message.attachments.first
    type = avisa_media_type(attachment.file_type)
    caption = message.content.to_s.presence

    result = dispatch_media(phone_number, attachment, type, caption)
    result && result[:id]
  rescue Whatsapp::Providers::AvisaClient::Error => e
    Rails.logger.error("[AVISA] envio de mídia falhou (type=#{type}): #{e.message}")
    message.update!(status: :failed, external_error: "Avisa: #{e.message}")
    nil
  rescue ActiveStorage::FileNotFoundError => e
    Rails.logger.error("[AVISA] arquivo não encontrado no worker (configurar S3/R2 compartilhado): #{e.message}")
    message.update!(status: :failed, external_error: 'Storage compartilhado não configurado (S3/R2). Anexos não são visíveis entre web e worker.')
    nil
  end

  def dispatch_media(phone_number, attachment, type, caption)
    case type
    when 'image'
      client.send_image_base64(number: phone_number, data_uri: data_uri_for(attachment), caption: caption)
    when 'document'
      client.send_document_base64(
        number: phone_number,
        data_uri: data_uri_for(attachment),
        file_name: attachment.file.filename.to_s,
        caption: caption
      )
    when 'audio'
      client.send_audio_base64(number: phone_number, base64_payload: Base64.strict_encode64(blob_bytes(attachment)))
    else
      send_media_via_url(phone_number, attachment, type, caption)
    end
  end

  # Vídeo (e tipos desconhecidos) ainda dependem de URL pública — requer
  # ACTIVE_STORAGE_SERVICE apontando pra S3/R2/similar.
  def send_media_via_url(phone_number, attachment, type, caption)
    client.send_media(
      number: phone_number,
      type: type,
      file_url: attachment.download_url,
      caption: caption,
      file_name: attachment.file.filename.to_s
    )
  end

  def data_uri_for(attachment)
    mime = attachment.file.content_type.presence || 'application/octet-stream'
    "data:#{mime};base64,#{Base64.strict_encode64(blob_bytes(attachment))}"
  end

  def blob_bytes(attachment)
    bytes = +''
    attachment.file.blob.open { |file| bytes << file.read }
    bytes
  end

  def avisa_media_type(chatwoot_file_type)
    case chatwoot_file_type.to_s
    when 'image' then 'image'
    when 'audio' then 'audio'
    when 'video' then 'video'
    else 'document'
    end
  end
end
