class Whatsapp::IncomingMessageZapiService < Whatsapp::IncomingMessageBaseService
  include Events::Types
  include Whatsapp::ZapiHandlers::ConnectedCallback
  include Whatsapp::ZapiHandlers::DisconnectedCallback
  include Whatsapp::ZapiHandlers::ReceivedCallback
  include Whatsapp::ZapiHandlers::DeliveryCallback
  include Whatsapp::ZapiHandlers::MessageStatusCallback

  def perform
    return if processed_params[:type].blank?

    Rails.configuration.dispatcher.dispatch(PROVIDER_EVENT_RECEIVED, Time.zone.now, inbox: inbox, event: processed_params[:type],
                                                                                    payload: processed_params)

    event_prefix = processed_params[:type].underscore
    method_name = "process_#{event_prefix}"
    if respond_to?(method_name, true)
      send(method_name)
    else
      Rails.logger.warn "Z-API unsupported event: #{processed_params.inspect}"
    end
  end
end
