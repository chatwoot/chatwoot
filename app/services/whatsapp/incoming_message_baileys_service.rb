class Whatsapp::IncomingMessageBaileysService < Whatsapp::IncomingMessageBaseService
  include Events::Types
  include Whatsapp::BaileysHandlers::ConnectionUpdate
  include Whatsapp::BaileysHandlers::MessagesUpsert
  include Whatsapp::BaileysHandlers::MessagesUpdate
  include Whatsapp::BaileysHandlers::MessageReceiptUpdate
  include Whatsapp::BaileysHandlers::GroupParticipantsUpdate
  include Whatsapp::BaileysHandlers::GroupsUpdate
  include Whatsapp::BaileysHandlers::GroupsActivity

  class InvalidWebhookVerifyToken < StandardError; end

  def perform # rubocop:disable Metrics/AbcSize
    raise InvalidWebhookVerifyToken if processed_params[:webhookVerifyToken] != inbox.channel.provider_config['webhook_verify_token']
    return if processed_params[:event].blank? || processed_params[:data].blank?

    Rails.configuration.dispatcher.dispatch(PROVIDER_EVENT_RECEIVED, Time.zone.now, inbox: inbox, event: processed_params[:event],
                                                                                    payload: processed_params[:data])

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
