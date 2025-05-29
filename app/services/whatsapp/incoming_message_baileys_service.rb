class Whatsapp::IncomingMessageBaileysService < Whatsapp::IncomingMessageBaseService
  include Whatsapp::BaileysHandlers::ConnectionUpdate
  include Whatsapp::BaileysHandlers::MessagesUpsert
  include Whatsapp::BaileysHandlers::MessagesUpdate

  class InvalidWebhookVerifyToken < StandardError; end

  def perform
    raise InvalidWebhookVerifyToken if processed_params[:webhookVerifyToken] != inbox.channel.provider_config['webhook_verify_token']
    return if processed_params[:event].blank? || processed_params[:data].blank?

    event_prefix = processed_params[:event].gsub(/[\.-]/, '_')
    method_name = "process_#{event_prefix}"
    if respond_to?(method_name, true)
      # TODO: Implement the methods for all expected events
      send(method_name)
    else
      Rails.logger.warn "Baileys unsupported event: #{processed_params[:event]}"
    end
  end
end
