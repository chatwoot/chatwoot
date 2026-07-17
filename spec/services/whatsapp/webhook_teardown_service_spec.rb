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
            'phone_number_id' => 'test_phone_id',
            'api_key' => 'test_api_key'
          }
        )
      end

      it 'calls clear_phone_number_callback_override on Facebook API client' do
        api_client = instance_double(Whatsapp::FacebookApiClient)
        allow(Whatsapp::FacebookApiClient).to receive(:new).with('test_api_key').and_return(api_client)
        allow(api_client).to receive(:clear_phone_number_callback_override).with('test_phone_id')

        service.perform

        expect(api_client).to have_received(:clear_phone_number_callback_override).with('test_phone_id')
      end

      it 'handles errors gracefully without raising' do
        api_client = instance_double(Whatsapp::FacebookApiClient)
        allow(Whatsapp::FacebookApiClient).to receive(:new).and_return(api_client)
        allow(api_client).to receive(:clear_phone_number_callback_override).and_raise(StandardError, 'API Error')

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

    context 'when channel is whatsapp_cloud with manual setup' do
      before do
        allow(channel).to receive(:setup_webhooks).and_return(true)

        channel.update!(
          provider: 'whatsapp_cloud',
          provider_config: {
            'source' => 'manual',
            'phone_number_id' => 'manual_phone_id',
            'business_account_id' => 'manual_waba_id',
            'api_key' => 'manual_api_key'
          }
        )
      end

      it 'clears the phone number callback override' do
        api_client = instance_double(Whatsapp::FacebookApiClient)
        allow(Whatsapp::FacebookApiClient).to receive(:new).with('manual_api_key').and_return(api_client)
        allow(api_client).to receive(:clear_phone_number_callback_override).with('manual_phone_id')

        service.perform

        expect(api_client).to have_received(:clear_phone_number_callback_override).with('manual_phone_id')
      end

      # The manual token belongs to the customer's own Meta app, so its WABA subscription is not ours to remove.
      it 'does not unsubscribe the app from the WABA' do
        api_client = instance_double(Whatsapp::FacebookApiClient)
        allow(Whatsapp::FacebookApiClient).to receive(:new).and_return(api_client)
        allow(api_client).to receive(:clear_phone_number_callback_override)
        allow(api_client).to receive(:unsubscribe_app_from_waba)

        service.perform

        expect(api_client).not_to have_received(:unsubscribe_app_from_waba)
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
