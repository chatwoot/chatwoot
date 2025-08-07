require 'rails_helper'

RSpec.describe Whatsapp::WebhookTeardownService do
  describe '#perform' do
    let(:channel) { create(:channel_whatsapp, validate_provider_config: false, sync_templates: false) }
    let(:service) { described_class.new(channel) }

    context 'when channel is whatsapp_cloud with embedded_signup' do
      before do
        # Stub webhook setup to prevent HTTP calls during channel update
        allow(channel).to receive(:setup_webhooks).and_return(true)

        channel.update!(
          provider: 'whatsapp_cloud',
          provider_config: {
            'source' => 'embedded_signup',
            'business_account_id' => 'test_waba_id',
            'api_key' => 'test_api_key'
          }
        )
      end

      it 'calls unsubscribe_waba_webhook on Facebook API client' do
        api_client = instance_double(Whatsapp::FacebookApiClient)
        allow(Whatsapp::FacebookApiClient).to receive(:new).with('test_api_key').and_return(api_client)
        allow(api_client).to receive(:unsubscribe_waba_webhook).with('test_waba_id')

        service.perform

        expect(api_client).to have_received(:unsubscribe_waba_webhook).with('test_waba_id')
      end

      it 'handles errors gracefully without raising' do
        api_client = instance_double(Whatsapp::FacebookApiClient)
        allow(Whatsapp::FacebookApiClient).to receive(:new).and_return(api_client)
        allow(api_client).to receive(:unsubscribe_waba_webhook).and_raise(StandardError, 'API Error')

        expect { service.perform }.not_to raise_error
      end
    end

    context 'when channel is not whatsapp_cloud' do
      before do
        channel.update!(provider: 'default')
      end

      it 'does not attempt to unsubscribe webhook' do
        expect(Whatsapp::FacebookApiClient).not_to receive(:new)

        service.perform
      end
    end

    context 'when channel is whatsapp_cloud but not embedded_signup' do
      before do
        channel.update!(
          provider: 'whatsapp_cloud',
          provider_config: { 'source' => 'manual' }
        )
      end

      it 'does not attempt to unsubscribe webhook' do
        expect(Whatsapp::FacebookApiClient).not_to receive(:new)

        service.perform
      end
    end

    context 'when required config is missing' do
      before do
        channel.update!(
          provider: 'whatsapp_cloud',
          provider_config: { 'source' => 'embedded_signup' }
        )
      end

      it 'does not attempt to unsubscribe webhook' do
        expect(Whatsapp::FacebookApiClient).not_to receive(:new)

        service.perform
      end
    end
  end
end
