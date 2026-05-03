require 'rails_helper'

RSpec.describe Whatsapp::AppIdResolver do
  describe '#find' do
    it 'prefers the Chatwit global config value' do
      channel = instance_double(Channel::Whatsapp, provider_config: { 'whatsapp_app_id' => 'provider-app' })
      allow(GlobalConfigService).to receive(:load).with('WHATSAPP_APP_ID', '').and_return('global-app')

      expect(described_class.new(channel).find).to eq('global-app')
    end

    it 'uses the provider config value when global config and env values are blank' do
      channel = instance_double(Channel::Whatsapp, provider_config: { 'whatsapp_app_id' => 'provider-app' })
      allow(GlobalConfigService).to receive(:load).with('WHATSAPP_APP_ID', '').and_return('')
      allow(ENV).to receive(:fetch).with('WHATSAPP_APP_ID', nil).and_return(nil)
      allow(ENV).to receive(:fetch).with('META_APP_ID', nil).and_return(nil)

      expect(described_class.new(channel).find).to eq('provider-app')
    end
  end
end
