# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Whatsapp::ProviderConfigFactory do
  let(:account) { create(:account) }

  describe '.create' do
    it 'creates WhatsappCloud config for whatsapp_cloud provider' do
      channel = create(:channel_whatsapp, provider: 'whatsapp_cloud', account: account, validate_provider_config: false, sync_templates: false)

      config = described_class.create(channel)

      expect(config).to be_a(Whatsapp::ProviderConfig::WhatsappCloud)
    end

    it 'creates Whapi config for whapi provider' do
      channel = create(:channel_whatsapp, provider: 'whapi', account: account, validate_provider_config: false, sync_templates: false)

      config = described_class.create(channel)

      expect(config).to be_a(Whatsapp::ProviderConfig::Whapi)
    end

    it 'creates Whatsapp360Dialog config for default provider' do
      channel = create(:channel_whatsapp, provider: 'default', account: account, validate_provider_config: false, sync_templates: false)

      config = described_class.create(channel)

      expect(config).to be_a(Whatsapp::ProviderConfig::Whatsapp360Dialog)
    end
  end
end