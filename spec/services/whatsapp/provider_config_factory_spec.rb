# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Whatsapp::ProviderConfigFactory do
  let(:account) { create(:account) }

  # Add HTTP stubs for all provider API calls to prevent external requests during tests
  before do
    # Stub WhatsApp Cloud API calls for validation
    stub_request(:get, %r{https://graph\.facebook\.com/v\d+\.\d+/.*/message_templates})
      .to_return(status: 200, body: '{"data": []}', headers: { 'Content-Type' => 'application/json' })
    
    # Stub 360Dialog API calls
    stub_request(:post, 'https://waba.360dialog.io/v1/configs/webhook')
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })
    
    # Stub WHAPI health check
    stub_request(:get, 'https://gate.whapi.cloud/health')
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })
  end

  describe '.create' do
    it 'creates WhatsappCloud config for whatsapp_cloud provider' do
      channel = build(:channel_whatsapp, provider: 'whatsapp_cloud', account: account, validate_provider_config: false, sync_templates: false)
      allow(channel).to receive(:sync_templates)
      channel.save!(validate: false)

      config = described_class.create(channel)

      expect(config).to be_a(Whatsapp::ProviderConfig::WhatsappCloud)
    end

    it 'creates Whapi config for whapi provider' do
      channel = build(:channel_whatsapp, provider: 'whapi', account: account, validate_provider_config: false, sync_templates: false)
      allow(channel).to receive(:sync_templates)
      channel.save!(validate: false)

      config = described_class.create(channel)

      expect(config).to be_a(Whatsapp::ProviderConfig::Whapi)
    end

    it 'creates Whatsapp360Dialog config for default provider' do
      channel = build(:channel_whatsapp, provider: 'default', account: account, validate_provider_config: false, sync_templates: false)
      allow(channel).to receive(:sync_templates)
      channel.save!(validate: false)

      config = described_class.create(channel)

      expect(config).to be_a(Whatsapp::ProviderConfig::Whatsapp360Dialog)
    end
  end
end