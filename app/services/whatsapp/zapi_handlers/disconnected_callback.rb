module Whatsapp::ZapiHandlers::DisconnectedCallback
  include Whatsapp::ZapiHandlers::Helpers

  private

  def process_disconnected_callback
    inbox.channel.update_provider_connection!(connection: 'close')
  end
end
