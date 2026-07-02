# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Autonomia::Prospecting::Config do
  describe '.enabled?' do
    let(:account) { create(:account) }

    it 'uses the account internal attribute' do
      expect(described_class.enabled?(account)).to be false

      account.update!(internal_attributes: { 'autonomia_prospecting_enabled' => true })

      expect(described_class.enabled?(account.reload)).to be true
    end
  end

  describe '.enable_for!' do
    it 'enables the account internal attribute' do
      account = create(:account)

      described_class.enable_for!(account)

      expect(account.reload.internal_attributes['autonomia_prospecting_enabled']).to be true
    end
  end

  describe '.disable_for!' do
    it 'disables the account internal attribute' do
      account = create(:account)
      account.update!(internal_attributes: { 'autonomia_prospecting_enabled' => true })

      described_class.disable_for!(account)

      expect(account.reload.internal_attributes['autonomia_prospecting_enabled']).to be false
    end
  end
end
