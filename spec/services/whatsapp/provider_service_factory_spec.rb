# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Whatsapp::ProviderServiceFactory do
  let(:account) { create(:account) }

  describe '.create' do
    it 'creates WhatsappCloudService for whatsapp_cloud provider' do
      channel = create(:channel_whatsapp, provider: 'whatsapp_cloud', account: account, validate_provider_config: false, sync_templates: false)

      service = described_class.create(channel)

      expect(service).to be_a(Whatsapp::Providers::WhatsappCloudService)
    end

    it 'creates WhapiService for whapi provider' do
      channel = create(:channel_whatsapp, provider: 'whapi', account: account, validate_provider_config: false, sync_templates: false)

      service = described_class.create(channel)

      expect(service).to be_a(Whatsapp::Providers::WhapiService)
    end

    it 'creates Whatsapp360DialogService for default provider' do
      channel = create(:channel_whatsapp, provider: 'default', account: account, validate_provider_config: false, sync_templates: false)

      service = described_class.create(channel)

      expect(service).to be_a(Whatsapp::Providers::Whatsapp360DialogService)
    end
  end
end