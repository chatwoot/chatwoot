# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Whatsapp::ProviderConfig::Whapi do
  let(:account) { create(:account) }
  let(:provider_config) { { 'whapi_channel_id' => 'test_channel_id' } }
  let(:channel) do
    create(:channel_whatsapp, provider: 'whapi', provider_config: provider_config, account: account, validate_provider_config: false,
                              sync_templates: false)
  end
  let(:config) { described_class.new(channel) }

  describe '#validate_config?' do
    it 'delegates to the Whapi service for validation' do
      whapi_service = instance_double(Whatsapp::Providers::WhapiService)
      allow(Whatsapp::Providers::WhapiService).to receive(:new).with(whatsapp_channel: channel).and_return(whapi_service)
      allow(whapi_service).to receive(:validate_provider_config?).and_return(true)

      expect(config.validate_config?).to be true
    end
  end

  describe '#webhook_verify_token' do
    it 'returns nil as Whapi does not use webhook verify tokens' do
      expect(config.webhook_verify_token).to be_nil
    end
  end

  describe '#cleanup_on_destroy' do
    it 'enqueues cleanup job for partner channels' do
      expect(Whatsapp::Whapi::WhapiChannelCleanupJob).to receive(:perform_later).with('test_channel_id')
      config.cleanup_on_destroy
    end
  end
end