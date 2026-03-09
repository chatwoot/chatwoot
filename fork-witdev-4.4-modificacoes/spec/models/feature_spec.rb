# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Feature do
  let(:account) { create(:account) }

  describe '.get' do
    it 'delegates to FeatureService.get' do
      expect(FeatureService).to receive(:get).with(:SOCIALWISE_RICH_DASHBOARD, account.id)

      described_class.get(:SOCIALWISE_RICH_DASHBOARD, account.id)
    end

    it 'works without account_id' do
      expect(FeatureService).to receive(:get).with(:SOCIALWISE_RICH_DASHBOARD, nil)

      described_class.get(:SOCIALWISE_RICH_DASHBOARD)
    end
  end

  describe '.enabled_globally?' do
    it 'delegates to FeatureService.enabled_globally?' do
      expect(FeatureService).to receive(:enabled_globally?).with(:SOCIALWISE_RICH_DASHBOARD)

      described_class.enabled_globally?(:SOCIALWISE_RICH_DASHBOARD)
    end
  end

  describe '.enabled_for_account?' do
    it 'delegates to FeatureService.enabled_for_account?' do
      expect(FeatureService).to receive(:enabled_for_account?).with(:SOCIALWISE_RICH_DASHBOARD, account.id)

      described_class.enabled_for_account?(:SOCIALWISE_RICH_DASHBOARD, account.id)
    end
  end

  describe '.set_account_flag' do
    it 'delegates to FeatureService.set_account_flag' do
      expect(FeatureService).to receive(:set_account_flag).with(:SOCIALWISE_RICH_DASHBOARD, account.id, true)

      described_class.set_account_flag(:SOCIALWISE_RICH_DASHBOARD, account.id, true)
    end
  end

  describe '.remove_account_flag' do
    it 'delegates to FeatureService.remove_account_flag' do
      expect(FeatureService).to receive(:remove_account_flag).with(:SOCIALWISE_RICH_DASHBOARD, account.id)

      described_class.remove_account_flag(:SOCIALWISE_RICH_DASHBOARD, account.id)
    end
  end

  describe '.accounts_with_flag' do
    it 'delegates to FeatureService.accounts_with_flag' do
      expect(FeatureService).to receive(:accounts_with_flag).with(:SOCIALWISE_RICH_DASHBOARD)

      described_class.accounts_with_flag(:SOCIALWISE_RICH_DASHBOARD)
    end
  end

  describe '.clear_cache' do
    it 'delegates to FeatureService.clear_cache' do
      expect(FeatureService).to receive(:clear_cache)

      described_class.clear_cache
    end
  end

  describe 'task requirement pattern verification' do
    it 'supports the documented pattern: Feature.get(:SOCIALWISE_RICH_DASHBOARD, account_id)' do
      expect(FeatureService).to receive(:get).with(:SOCIALWISE_RICH_DASHBOARD, account.id)

      # This is the exact pattern documented in the task
      Feature.get(:SOCIALWISE_RICH_DASHBOARD, account.id)
    end

    it 'supports the pattern without account_id for global flags' do
      expect(FeatureService).to receive(:get).with(:SOCIALWISE_RICH_DASHBOARD, nil)

      Feature.get(:SOCIALWISE_RICH_DASHBOARD)
    end
  end
end