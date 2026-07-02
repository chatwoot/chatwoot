# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Autonomia::Prospecting::Config do
  describe '.enabled?' do
    let(:account) { create(:account) }

    it 'uses the account feature flag' do
      expect(described_class.enabled?(account)).to be false

      account.enable_features!('autonomia_prospecting')

      expect(described_class.enabled?(account.reload)).to be true
    end

    it 'does not use the legacy internal attribute gate' do
      account.update!(internal_attributes: { 'autonomia_prospecting_enabled' => true })

      expect(described_class.enabled?(account.reload)).to be false
    end
  end

  describe '.enable_for!' do
    it 'enables the account feature flag' do
      account = create(:account)

      described_class.enable_for!(account)

      expect(account.reload.feature_enabled?('autonomia_prospecting')).to be true
    end
  end

  describe '.disable_for!' do
    it 'disables the account feature flag' do
      account = create(:account)
      account.enable_features!('autonomia_prospecting')

      described_class.disable_for!(account)

      expect(account.reload.feature_enabled?('autonomia_prospecting')).to be false
    end
  end
end
