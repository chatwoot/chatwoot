require 'rails_helper'

describe Whatsapp::ZapiHandlers::DisconnectedCallback do
  let!(:whatsapp_channel) do
    create(:channel_whatsapp, provider: 'zapi', validate_provider_config: false)
  end
  let(:inbox) { whatsapp_channel.inbox }
  let(:service) { Whatsapp::IncomingMessageZapiService.new(inbox: inbox, params: params) }

  describe '#process_disconnected_callback' do
    let(:params) { { type: 'DisconnectedCallback' } }

    it 'updates provider connection to close' do
      service.perform

      expect(whatsapp_channel.reload.provider_connection['connection']).to eq('close')
    end
  end
end
