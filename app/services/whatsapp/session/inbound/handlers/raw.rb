# A provider event with no canonical meaning. It is not stored; it only reaches the
# webhooks that subscribe to raw provider traffic.
class Whatsapp::Session::Inbound::Handlers::Raw < Whatsapp::Session::Inbound::Handlers::Base
  def perform
    Rails.configuration.dispatcher.dispatch(
      Events::Types::PROVIDER_EVENT_RECEIVED, Time.zone.now,
      inbox: inbox, event: payload.provider_event, payload: payload.data
    )
    :handled
  end
end
