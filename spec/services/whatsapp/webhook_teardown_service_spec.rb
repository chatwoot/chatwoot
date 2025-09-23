require 'rails_helper'

RSpec.describe Whatsapp::WebhookTeardownService do
  describe '#perform' do
    let(:account) { create(:account) }
    let(:api_client) { double }
    let(:channel) do
      create(:channel_whatsapp,
             account: account,
             provider: 'whatsapp_cloud',
             provider_config: {
               'source' => 'embedded_signup',
               'business_account_id' => 'test_waba_id',
               'api_key' => 'test_access_token'
             },
             sync_templates: false)
    end

    before do
      allow(Whatsapp::FacebookApiClient).to receive(:new).and_return(api_client)
      # Stub webhook setup to prevent HTTP calls during channel update
      allow(channel).to receive(:setup_webhooks).and_return(true)
    end

    context 'when channel is whatsapp_cloud with embedded_signup' do
      before do
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
        allow(api_client).to receive(:unsubscribe_waba_webhook).with('test_waba_id')

        service.perform

        expect(api_client).to have_received(:unsubscribe_waba_webhook).with('test_waba_id')
      end

      it 'handles errors gracefully without raising' do
        allow(api_client).to receive(:unsubscribe_waba_webhook).and_raise(StandardError, 'API error')
        expect { described_class.new(channel: channel).perform }.not_to raise_error
      end
    end

    it 'does not attempt to unsubscribe webhook when channel is not whatsapp_cloud' do
      other_channel = create(:channel_api, account: account)
      expect(api_client).not_to receive(:unsubscribe_waba_webhook)
      described_class.new(channel: other_channel).perform
    end

    it 'does not attempt to unsubscribe webhook when channel is whatsapp_cloud but not embedded_signup' do
      channel = create(:channel_whatsapp,
                       account: account,
                       provider: 'whatsapp_cloud',
                       provider_config: {
                         'source' => 'manual',
                         'business_account_id' => 'test_waba_id',
                         'api_key' => 'test_access_token'
                       },
                       sync_templates: false)
      expect(api_client).not_to receive(:unsubscribe_waba_webhook)
      described_class.new(channel: channel).perform
    end

    it 'does not attempt to unsubscribe webhook when required config is missing' do
      channel = create(:channel_whatsapp,
                       account: account,
                       provider: 'whatsapp_cloud',
                       provider_config: {
                         'source' => 'embedded_signup',
                         'business_account_id' => 'test_waba_id'
                         # api_key is missing
                       },
                       sync_templates: false)
      expect(api_client).not_to receive(:unsubscribe_waba_webhook)
      described_class.new(channel: channel).perform
    end
  end
end
