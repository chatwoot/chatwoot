require 'rails_helper'

RSpec.describe Shopify::FeatureGate do
  let(:account) { create(:account) }

  before do
    allow(GlobalConfigService).to receive(:load)
      .with(described_class::GLOBAL_CONFIG, 'false')
      .and_return(global_config)
  end

  context 'when the installation switch is disabled' do
    let(:global_config) { false }

    it 'disables account-less and account-scoped Shopify behavior' do
      account.enable_features(described_class::ACCOUNT_FEATURE)

      expect(described_class.enabled?).to be false
      expect(described_class.enabled?(account: account)).to be false
    end
  end

  context 'when the installation switch is enabled' do
    let(:global_config) { true }

    it 'enables account-less Shopify behavior' do
      expect(described_class.enabled?).to be true
    end

    it 'requires the account feature for account-scoped behavior' do
      expect(described_class.enabled?(account: account)).to be false

      account.enable_features(described_class::ACCOUNT_FEATURE)

      expect(described_class.enabled?(account: account)).to be true
    end
  end
end
