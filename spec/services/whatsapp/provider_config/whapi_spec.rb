# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Whatsapp::ProviderConfig::Whapi do
  let(:account) { create(:account) }
  let(:provider_config) { { 'whapi_channel_id' => 'test_channel_id', 'whapi_channel_token' => 'test_token', 'connection_status' => 'pending' } }
  let(:channel) do
    ch = build(:channel_whatsapp, provider: 'whapi', provider_config: provider_config, account: account, validate_provider_config: false,
                                  sync_templates: false)
    allow(ch).to receive(:sync_templates)
    ch.save!(validate: false)
    
    # Create inbox manually to avoid factory validation
    inbox = Inbox.new(name: 'Test Inbox', account: ch.account, channel: ch)
    inbox.save!(validate: false)
    
    ch
  end
  let(:config) { described_class.new(channel) }

  before do
    # Stub WHAPI health check endpoint
    stub_request(:get, 'https://gate.whapi.cloud/health')
      .to_return(status: 200, body: '{}')
  end

  describe '#validate_config?' do
    it 'delegates to the Whapi service for validation' do
      # For partner channels with pending status, it should return true without health check
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