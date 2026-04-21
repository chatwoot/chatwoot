# CUSTOMIZAÇÃO_SYNAPSEOS
# Webhook controller para mensagens recebidas via Hyperflow.
# A Hyperflow publica eventos num payload compatível com a WhatsApp Cloud API.
# TODO_HYPERFLOW: confirmar o formato exato do payload e do header de assinatura.
class Webhooks::HyperflowController < ActionController::API
  # Meta exige GET com hub.challenge no handshake; mantemos o mesmo padrão.
  def verify
    channel = Channel::Whatsapp.find_by(phone_number: params[:phone_number])
    token = channel&.provider_config&.dig('webhook_verify_token')
    if token.present? && params['hub.verify_token'] == token
      render plain: params['hub.challenge']
    else
      head :unauthorized
    end
  end

  def process_payload
    channel = Channel::Whatsapp.find_by(phone_number: params[:phone_number])
    return render json: { error: 'Unknown phone_number' }, status: :not_found if channel.nil?
    return render json: { error: 'Wrong provider' }, status: :unprocessable_entity if channel.provider != 'hyperflow'

    Whatsapp::IncomingMessageHyperflowService.new(inbox: channel.inbox, params: params.to_unsafe_hash).perform
    head :ok
  rescue StandardError => e
    Rails.logger.error("[HYPERFLOW webhook] #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    head :internal_server_error
  end
end
