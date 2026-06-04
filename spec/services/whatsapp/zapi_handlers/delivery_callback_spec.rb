require 'rails_helper'

describe Whatsapp::ZapiHandlers::DeliveryCallback do
  let!(:whatsapp_channel) do
    create(:channel_whatsapp, provider: 'zapi', validate_provider_config: false)
  end
  let(:inbox) { whatsapp_channel.inbox }
  let(:service) { Whatsapp::IncomingMessageZapiService.new(inbox: inbox, params: params) }

  describe '#process_delivery_callback' do
    let(:message) { create(:message, inbox: inbox, source_id: 'msg_456') }
    let(:params) do
      {
        type: 'DeliveryCallback',
        messageId: message.source_id,
        momment: Time.current.to_i * 1000
      }
    end

    it 'updates message status to delivered' do
      service.perform

      expect(message.reload.status).to eq('delivered')
      expect(message.external_created_at).to eq(params[:momment] / 1000)
    end

    it 'updates message status to failed when error is present' do
      params[:error] = 'Message delivery failed'

      service.perform

      expect(message.reload.status).to eq('failed')
      expect(message.external_error).to eq('Message delivery failed')
    end

    it 'does nothing when message is not found' do
      params[:messageId] = 'non_existent_message'

      expect do
        service.perform
      end.not_to change(message, :status)
    end
  end
end
