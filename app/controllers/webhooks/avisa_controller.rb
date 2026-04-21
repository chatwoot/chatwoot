# CUSTOMIZAÇÃO_SYNAPSEOS
# Webhook controller para mensagens recebidas via Avisa API (não-oficial).
class Webhooks::AvisaController < ActionController::API
  def process_payload
    channel = Channel::Whatsapp.find_by(phone_number: params[:phone_number])
    return render json: { error: 'Unknown phone_number' }, status: :not_found if channel.nil?
    return render json: { error: 'Wrong provider' }, status: :unprocessable_entity if channel.provider != 'avisa'

    Whatsapp::IncomingMessageAvisaService.new(inbox: channel.inbox, params: params.to_unsafe_hash).perform
    head :ok
  rescue StandardError => e
    Rails.logger.error("[AVISA webhook] #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    head :internal_server_error
  end
end
