require 'rails_helper'

RSpec.describe UnknownSignInNotification do
  describe '.enabled?' do
    before { GlobalConfig.clear_cache }

    it 'is false by default' do
      expect(described_class.enabled?).to be false
    end

    it 'is true when the installation config is enabled' do
      create(:installation_config, name: 'UNKNOWN_SIGNIN_NOTIFICATION_ENABLED', value: true)
      GlobalConfig.clear_cache
      expect(described_class.enabled?).to be true
    end

    it 'is false when the installation config is disabled' do
      create(:installation_config, name: 'UNKNOWN_SIGNIN_NOTIFICATION_ENABLED', value: false)
      GlobalConfig.clear_cache
      expect(described_class.enabled?).to be false
    end
  end
end
