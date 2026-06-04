require 'rails_helper'

describe Whatsapp::ZapiHandlers::ConnectedCallback do
  let!(:whatsapp_channel) do
    create(:channel_whatsapp, provider: 'zapi', validate_provider_config: false)
  end
  let(:inbox) { whatsapp_channel.inbox }
  let(:service) { Whatsapp::IncomingMessageZapiService.new(inbox: inbox, params: params) }

  describe '#process_connected_callback' do
    let(:params) do
      {
        type: 'ConnectedCallback',
        phone: whatsapp_channel.phone_number.delete('+')
      }
    end

    it 'updates provider connection to open when phone numbers match' do
      service.perform

      expect(whatsapp_channel.reload.provider_connection['connection']).to eq('open')
    end

    it 'updates provider connection to close when phone numbers do not match' do
      params[:phone] = '5511123456789'
      allow(whatsapp_channel).to receive(:disconnect_channel_provider)

      service.perform

      expect(whatsapp_channel.reload.provider_connection['connection']).to eq('close')
      expect(whatsapp_channel.provider_connection['error']).to eq(I18n.t('errors.inboxes.channel.provider_connection.wrong_phone_number'))
      expect(whatsapp_channel).to have_received(:disconnect_channel_provider)
    end

    it 'handles Brazil mobile number normalization' do
      whatsapp_channel.update!(phone_number: '+5511987654321')
      params[:phone] = '551187654321' # Without leading digit '9'

      service.perform

      expect(whatsapp_channel.reload.provider_connection['connection']).to eq('open')
    end
  end
end
