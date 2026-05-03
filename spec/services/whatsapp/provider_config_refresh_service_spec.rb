require 'rails_helper'

RSpec.describe Whatsapp::ProviderConfigRefreshService do
  describe '#perform' do
    it 'persists the resolved WhatsApp App ID on the channel provider config' do
      channel = create(
        :channel_whatsapp,
        provider: 'whatsapp_cloud',
        sync_templates: false,
        validate_provider_config: false,
        provider_config: {
          'api_key' => 'token',
          'phone_number_id' => 'phone-123',
          'business_account_id' => 'waba-123'
        }
      )
      allow(GlobalConfigService).to receive(:load).with('WHATSAPP_APP_ID', '').and_return('app-123')

      result = described_class.new(channel).perform

      expect(result).to include(success: true, whatsapp_app_id: 'app-123')
      expect(channel.reload.provider_config['whatsapp_app_id']).to eq('app-123')
    end

    it 'returns a failure when the App ID is not configured' do
      channel = create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)
      allow(GlobalConfigService).to receive(:load).with('WHATSAPP_APP_ID', '').and_return('')
      allow(ENV).to receive(:fetch).with('WHATSAPP_APP_ID', nil).and_return(nil)
      allow(ENV).to receive(:fetch).with('META_APP_ID', nil).and_return(nil)

      result = described_class.new(channel).perform

      expect(result).to include(success: false, error: 'WHATSAPP_APP_ID is not configured in Chatwit')
    end

    it 'uses an explicit App ID provided by the inbox configuration UI' do
      channel = create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)
      allow(GlobalConfigService).to receive(:load).with('WHATSAPP_APP_ID', '').and_return('')

      result = described_class.new(channel, whatsapp_app_id: 'ui-app-123').perform

      expect(result).to include(success: true, whatsapp_app_id: 'ui-app-123')
      expect(channel.reload.provider_config['whatsapp_app_id']).to eq('ui-app-123')
    end
  end
end
