require 'rails_helper'

RSpec.describe Shopify::FeatureGate do
  let(:account) { create(:account) }

  around do |example|
    with_modified_env described_class::GLOBAL_CONFIG => nil do
      example.run
    end
  end

  before do
    GlobalConfig.clear_cache
  end

  context 'when the installation switch is disabled' do
    before do
      create(:installation_config, name: described_class::GLOBAL_CONFIG, value: false)
    end

    it 'disables account-less and account-scoped Shopify behavior' do
      account.enable_features(described_class::ACCOUNT_FEATURE)

      expect(described_class.enabled?).to be false
      expect(described_class.enabled?(account: account)).to be false
    end

    it 'reads the stored switch without clearing other cached configs' do
      GlobalConfig.get('ENABLE_ACCOUNT_SIGNUP')

      expect(described_class.enabled?).to be false

      expect(InstallationConfig).not_to receive(:find_by)
      GlobalConfig.get('ENABLE_ACCOUNT_SIGNUP')
    end

    it 'does not create or modify installation configs' do
      expect { described_class.enabled? }.not_to change(InstallationConfig, :count)
    end
  end

  context 'when the installation switch is enabled' do
    before do
      create(:installation_config, name: described_class::GLOBAL_CONFIG, value: true)
    end

    it 'enables account-less Shopify behavior' do
      expect(described_class.enabled?).to be true
    end

    it 'requires the account feature for account-scoped behavior' do
      expect(described_class.enabled?(account: account)).to be false

      account.enable_features(described_class::ACCOUNT_FEATURE)

      expect(described_class.enabled?(account: account)).to be true
    end
  end

  context 'when the environment overrides the stored installation switch' do
    it 'uses a false environment value as a kill switch' do
      create(:installation_config, name: described_class::GLOBAL_CONFIG, value: true)

      with_modified_env described_class::GLOBAL_CONFIG => 'false' do
        expect(described_class.enabled?).to be false
      end
    end

    it 'uses a true environment value to enable the rollout' do
      create(:installation_config, name: described_class::GLOBAL_CONFIG, value: false)

      with_modified_env described_class::GLOBAL_CONFIG => 'true' do
        expect(described_class.enabled?).to be true
      end
    end
  end
end
