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

    context 'when channel is whatsapp_light' do
      before do
        allow(channel).to receive(:setup_webhooks).and_return(true)

        channel.update!(
          provider: 'whatsapp_light',
          provider_config: {
            'api_url' => 'https://gate.whapi.cloud/',
            'token' => 'test_token_123',
            'channel_id' => 'test_channel_123',
            'phone' => '1234567890'
          }
        )

        stub_request(:delete, 'https://manager.whapi.cloud/channels/test_channel_123')
          .to_return(status: 200, body: { success: true }.to_json)
      end

      it 'deletes the channel from Whapi' do
        service.perform

        expect(WebMock).to have_requested(:delete, 'https://manager.whapi.cloud/channels/test_channel_123')
          .with(
            headers: {
              'Authorization' => 'Bearer test_token_123',
              'Content-Type' => 'application/json'
            }
          )
      end

      it 'logs success message' do
        expect(Rails.logger).to receive(:info).with(/Channel test_channel_123 deleted successfully/)
        service.perform
      end

      context 'when channel_id is missing' do
        before do
          channel.provider_config.delete('channel_id')
          channel.save!
        end

        it 'does not make API call' do
          service.perform
          expect(WebMock).not_to have_requested(:delete, /channels/)
        end
      end

      context 'when token is missing' do
        before do
          channel.provider_config.delete('token')
          channel.save!
        end

        it 'does not make API call' do
          service.perform
          expect(WebMock).not_to have_requested(:delete, /channels/)
        end
      end

      context 'when Whapi API returns error' do
        before do
          stub_request(:delete, 'https://manager.whapi.cloud/channels/test_channel_123')
            .to_return(status: 400, body: { error: 'Channel not found' }.to_json)
        end

        it 'logs error message and does not raise' do
          expect(Rails.logger).to receive(:error).with(/Failed to delete channel/)
          expect { service.perform }.not_to raise_error
        end
      end

      context 'when network error occurs' do
        before do
          stub_request(:delete, 'https://manager.whapi.cloud/channels/test_channel_123')
            .to_raise(StandardError.new('Network error'))
        end

        it 'handles error gracefully' do
          expect(Rails.logger).to receive(:error).with(/Webhook teardown failed/)
          expect { service.perform }.not_to raise_error
        end
      end
    end
  end
end
