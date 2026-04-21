# CUSTOMIZAÇÃO_SYNAPSEOS
# Integração com Hyperflow via N8N.
#
# A Hyperflow não expõe uma API REST pública pra terceiros; o padrão
# recomendado (e adotado pelo produto Synapse OS) é usar o nó oficial
# `n8n-nodes-hyperflow-whatsapp` dentro do N8N. Portanto:
#
#   Chatwoot outgoing ──POST──> N8N webhook ──> nó Hyperflow ──> WhatsApp
#   WhatsApp ──> Hyperflow webhook ──> N8N ──POST──> Chatwoot /webhooks/hyperflow/...
#
# Esta classe é o lado de saída: ao enviar uma mensagem, faz POST no
# `n8n_outgoing_url` configurado no Channel::Whatsapp#provider_config.
# O payload é intencionalmente próximo do formato que o nó Hyperflow
# espera (`{ to, type, payload }`) pra o flow N8N ser um pass-through.
class Whatsapp::Providers::HyperflowService < Whatsapp::Providers::BaseService
  def send_message(phone_number, message)
    @message = message
    if message.attachments.present?
      send_attachment_message(phone_number, message)
    else
      send_text_message(phone_number, message)
    end
  end

  # Templates HSM ainda são enviados via N8N: o flow decide qual template
  # chamar no nó Hyperflow. Aqui só repassamos os parâmetros.
  def send_template(phone_number, template_info, message)
    post_to_n8n(
      message: message,
      body: {
        to: phone_number,
        type: 'template',
        payload: {
          name: template_info[:name],
          language: template_info[:language] || 'pt_BR',
          components: template_info[:components] || []
        }
      }
    )
  end

  # Sem sync: a lista de templates vive no painel da Hyperflow, não no Chatwoot.
  def sync_templates
    whatsapp_channel.mark_message_templates_updated
  end

  # Valida que o webhook do N8N está configurado. Não dispara a URL pra não
  # poluir o flow com chamadas "vazias" durante salvamento do inbox.
  def validate_provider_config?
    whatsapp_channel.provider_config['n8n_outgoing_url'].to_s =~ %r{\Ahttps?://.+}
  end

  def api_headers
    headers = { 'Content-Type' => 'application/json' }
    secret = whatsapp_channel.provider_config['webhook_secret']
    headers['X-Synapseos-Signature'] = secret if secret.present?
    headers
  end

  # O download de mídia também é delegado ao N8N: quando a mensagem
  # chega via webhook, o N8N já anexa a URL pública acessível.
  # Esse método existe só pra compatibilidade com chamadores internos.
  def media_url(media_id)
    media_id
  end

  private

  def send_text_message(phone_number, message)
    post_to_n8n(
      message: message,
      body: {
        to: phone_number,
        type: 'text',
        payload: { text: message.content.to_s }
      }
    )
  end

  def send_attachment_message(phone_number, message)
    attachment = message.attachments.first
    post_to_n8n(
      message: message,
      body: {
        to: phone_number,
        type: attachment_type_for(attachment),
        payload: {
          url: attachment.download_url,
          caption: message.content.to_s
        }
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
      Rails.logger.warn("[HYPERFLOW] n8n_outgoing_url não configurado no channel #{whatsapp_channel.id}")
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
    Rails.logger.error("[HYPERFLOW] POST para N8N falhou: #{e.class}: #{e.message}")
    nil
  end
end
