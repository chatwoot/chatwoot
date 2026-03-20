require 'rails_helper'

RSpec.describe Channels::Whatsapp::ZapiQrCodeJob do
  let(:whatsapp_channel) do
    create(:channel_whatsapp,
           provider: 'zapi',
           sync_templates: false,
           validate_provider_config: false,
           provider_config: {
             'instance_id' => 'test-instance',
             'token' => 'test-token',
             'client_token' => 'test-client-token'
           })
  end
  let(:zapi_service) { instance_double(Whatsapp::Providers::WhatsappZapiService) }

  before do
    allow(Whatsapp::Providers::WhatsappZapiService).to receive(:new)
      .with(whatsapp_channel: whatsapp_channel)
      .and_return(zapi_service)
  end

  describe '#perform' do
    it 'returns early on first attempt when connection is not close' do
      whatsapp_channel.update_provider_connection!(connection: 'open')

      expect(zapi_service).not_to receive(:qr_code_image)

      described_class.perform_now(whatsapp_channel, 1)
    end

    it 'returns early on subsequent attempts when connection is not connecting' do
      whatsapp_channel.update_provider_connection!(connection: 'open')

      expect(zapi_service).not_to receive(:qr_code_image)

      described_class.perform_now(whatsapp_channel, 2)
    end

    it 'fetches QR code and schedules next attempt on first attempt with blank connection' do
      allow(zapi_service).to receive(:qr_code_image).and_return('data:image/png;base64,test-qr-code')

      expect(described_class).to receive(:set).with(wait: 30.seconds).and_call_original
      expect do
        described_class.perform_now(whatsapp_channel, 1)
      end.to have_enqueued_job(described_class).with(whatsapp_channel, 2)

      expect(whatsapp_channel.reload.provider_connection['connection']).to eq('connecting')
      expect(whatsapp_channel.provider_connection['qr_data_url']).to eq('data:image/png;base64,test-qr-code')
    end

    it 'fetches QR code and schedules next attempt on first attempt with close connection' do
      whatsapp_channel.update_provider_connection!(connection: 'close')
      allow(zapi_service).to receive(:qr_code_image).and_return('data:image/png;base64,test-qr-code')

      expect(described_class).to receive(:set).with(wait: 30.seconds).and_call_original
      expect do
        described_class.perform_now(whatsapp_channel, 1)
      end.to have_enqueued_job(described_class).with(whatsapp_channel, 2)

      expect(whatsapp_channel.reload.provider_connection['connection']).to eq('connecting')
      expect(whatsapp_channel.provider_connection['qr_data_url']).to eq('data:image/png;base64,test-qr-code')
    end

    it 'fetches QR code and schedules next attempt on subsequent attempts with connecting connection' do
      whatsapp_channel.update_provider_connection!(connection: 'connecting')
      allow(zapi_service).to receive(:qr_code_image).and_return('data:image/png;base64,updated-qr-code')

      expect(described_class).to receive(:set).with(wait: 30.seconds).and_call_original
      expect do
        described_class.perform_now(whatsapp_channel, 2)
      end.to have_enqueued_job(described_class).with(whatsapp_channel, 3)

      whatsapp_channel.reload
      expect(whatsapp_channel.provider_connection['connection']).to eq('connecting')
      expect(whatsapp_channel.provider_connection['qr_data_url']).to eq('data:image/png;base64,updated-qr-code')
    end

    it 'does not update provider connection when QR code is blank' do
      whatsapp_channel.update_provider_connection!(connection: 'close')
      allow(zapi_service).to receive(:qr_code_image).and_return(nil)

      expect(whatsapp_channel).not_to receive(:update_provider_connection!)

      described_class.perform_now(whatsapp_channel, 1)
    end

    it 'avoids race condition when connection becomes open during processing' do
      whatsapp_channel.update_provider_connection!(connection: 'close')
      allow(zapi_service).to receive(:qr_code_image).and_return('data:image/png;base64,test-qr-code')
      allow(whatsapp_channel).to receive(:reload).and_return(whatsapp_channel)
      allow(whatsapp_channel).to receive(:provider_connection).and_return({ 'connection' => 'open' })

      expect(whatsapp_channel).not_to receive(:update_provider_connection!)

      described_class.perform_now(whatsapp_channel, 1)
    end

    it 'sets connection to close when maximum attempts exceeded' do
      whatsapp_channel.update_provider_connection!(connection: 'connecting')

      expect(zapi_service).not_to receive(:qr_code_image)
      expect(described_class).not_to receive(:set)

      described_class.perform_now(whatsapp_channel, 4)

      expect(whatsapp_channel.reload.provider_connection['connection']).to eq('close')
    end
  end
end
