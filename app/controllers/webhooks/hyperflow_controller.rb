# CUSTOMIZAÇÃO_SYNAPSEOS
# Recebe mensagens da Hyperflow encaminhadas pelo N8N.
#
# Contrato esperado:
# - POST /webhooks/hyperflow/:phone_number
#   body: payload Meta Cloud API (entry[].changes[].value.{messages,contacts})
#   header opcional: X-Synapseos-Signature (compara com provider_config['webhook_secret'])
class Webhooks::HyperflowController < ActionController::API
  # Mantido só pra conveniência: se você quiser testar o webhook com um
  # GET, devolve 200 se o secret bater.
  def verify
    channel = Channel::Whatsapp.find_by(phone_number: params[:phone_number])
    secret = channel&.provider_config&.dig('webhook_secret')
    if secret.present? && request.headers['X-Synapseos-Signature'] == secret
      head :ok
    else
      head :unauthorized
    end
  end

  def process_payload
    channel = Channel::Whatsapp.find_by(phone_number: params[:phone_number])
    return render json: { error: 'Unknown phone_number' }, status: :not_found if channel.nil?
    return render json: { error: 'Wrong provider' }, status: :unprocessable_entity if channel.provider != 'hyperflow'
    return head :unauthorized unless signature_valid?(channel)

    Whatsapp::IncomingMessageHyperflowService.new(
      inbox: channel.inbox,
      params: params.to_unsafe_hash
    ).perform
    head :ok
  rescue StandardError => e
    Rails.logger.error("[HYPERFLOW webhook] #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    head :internal_server_error
  end

  private

  def signature_valid?(channel)
    expected = channel.provider_config['webhook_secret']
    return true if expected.blank?

    request.headers['X-Synapseos-Signature'] == expected
  end
end
