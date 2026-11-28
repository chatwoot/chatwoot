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

      let!(:clear_override_request) do
        stub_request(:post, %r{\Ahttps://graph\.facebook\.com/v[\d.]+/test_phone_id\z})
          .with(body: { webhook_configuration: { override_callback_uri: '' } }.to_json)
          .to_return(status: 200, body: { success: true }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'clears the phone-level webhook override' do
        service.perform

        expect(clear_override_request).to have_been_requested
      end

      # Deregistration is number-wide, so it would also cut off other partners or the customer's own app on the number.
      it 'does not deregister the phone number' do
        service.perform

        expect(a_request(:post, %r{/test_phone_id/deregister})).not_to have_been_made
      end

      it 'handles errors gracefully without raising' do
        stub_request(:post, %r{/test_phone_id\z}).to_return(status: 500, body: { error: 'API Error' }.to_json)

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
            'api_key' => 'manual_api_key',
            'app_secret' => 'manual_app_secret'
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
