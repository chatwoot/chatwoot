# CUSTOMIZAÇÃO_SYNAPSEOS
# Recebe mensagens direto da Avisa API (sem N8N no meio).
#
# Contrato:
# - POST /webhooks/avisa
# - Content-Type: application/x-www-form-urlencoded (texto) ou multipart/form-data (mídia)
# - params[:token] = token da instância Avisa → autentica qual channel
# - params[:jsonData] = string JSON com o evento whatsmeow
# - params[:file] = binário descriptografado (só quando mídia; ignorado em v1)
class Webhooks::AvisaController < ActionController::API
  def process_payload
    token = params[:token].to_s
    return head :unauthorized if token.blank?

    channel = Channel::Whatsapp
              .where(provider: 'avisa')
              .where("provider_config->>'api_key' = ?", token)
              .first
    return head :unauthorized if channel.nil?

    Whatsapp::IncomingMessageAvisaService.new(
      inbox: channel.inbox,
      params: params.to_unsafe_hash
    ).perform
    head :ok
  rescue StandardError => e
    Rails.logger.error("[AVISA webhook] #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    head :internal_server_error
  end
end
