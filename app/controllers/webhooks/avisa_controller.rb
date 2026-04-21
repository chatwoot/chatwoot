# CUSTOMIZAÇÃO_SYNAPSEOS
# Recebe mensagens da Avisa API encaminhadas pelo N8N.
#
# Contrato esperado:
# - POST /webhooks/avisa/:phone_number
#   body: payload Meta Cloud API (entry[].changes[].value.{messages,contacts})
#   header opcional: X-Synapseos-Signature
class Webhooks::AvisaController < ActionController::API
  def process_payload
    channel = Channel::Whatsapp.find_by(phone_number: params[:phone_number])
    return render json: { error: 'Unknown phone_number' }, status: :not_found if channel.nil?
    return render json: { error: 'Wrong provider' }, status: :unprocessable_entity if channel.provider != 'avisa'
    return head :unauthorized unless signature_valid?(channel)

    Whatsapp::IncomingMessageAvisaService.new(
      inbox: channel.inbox,
      params: params.to_unsafe_hash
    ).perform
    head :ok
  rescue StandardError => e
    Rails.logger.error("[AVISA webhook] #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    head :internal_server_error
  end

  private

  def signature_valid?(channel)
    expected = channel.provider_config['webhook_secret']
    return true if expected.blank?

    request.headers['X-Synapseos-Signature'] == expected
  end
end
