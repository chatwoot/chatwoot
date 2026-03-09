# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FeatureService do
  let(:account) { create(:account) }
  let(:another_account) { create(:account) }

  before do
    # Clear cache before each test
    described_class.clear_cache
  end

  describe '.get' do
    context 'when no account_id is provided' do
      it 'returns global flag value when enabled' do
        allow(GlobalConfig).to receive(:get).with('SOCIALWISE_RICH_DASHBOARD')
                                            .and_return({ 'SOCIALWISE_RICH_DASHBOARD' => 'true' })

        result = described_class.get(:SOCIALWISE_RICH_DASHBOARD)
        expect(result).to be true
      end

      it 'returns false when global flag is disabled' do
        allow(GlobalConfig).to receive(:get).with('SOCIALWISE_RICH_DASHBOARD')
                                            .and_return({ 'SOCIALWISE_RICH_DASHBOARD' => nil })

        result = described_class.get(:SOCIALWISE_RICH_DASHBOARD)
        expect(result).to be false
      end
    end

    context 'when account_id is provided' do
      it 'returns account-specific flag when set' do
        # Set account-specific flag
        AccountFeatureFlag.create!(
          account: account,
          flag_name: 'SOCIALWISE_RICH_DASHBOARD',
          enabled: true
        )

        # Set global flag to false
        allow(GlobalConfig).to receive(:get).with('SOCIALWISE_RICH_DASHBOARD')
                                            .and_return({ 'SOCIALWISE_RICH_DASHBOARD' => nil })

        result = described_class.get(:SOCIALWISE_RICH_DASHBOARD, account.id)
        expect(result).to be true
      end

      it 'falls back to global flag when account flag is not set' do
        # No account-specific flag set
        # Set global flag to true
        allow(GlobalConfig).to receive(:get).with('SOCIALWISE_RICH_DASHBOARD')
                                            .and_return({ 'SOCIALWISE_RICH_DASHBOARD' => 'true' })

        result = described_class.get(:SOCIALWISE_RICH_DASHBOARD, account.id)
        expect(result).to be true
      end

      it 'prioritizes account flag over global flag' do
        # Set account-specific flag to false
        AccountFeatureFlag.create!(
          account: account,
          flag_name: 'SOCIALWISE_RICH_DASHBOARD',
          enabled: false
        )

        # Set global flag to true
        allow(GlobalConfig).to receive(:get).with('SOCIALWISE_RICH_DASHBOARD')
                                            .and_return({ 'SOCIALWISE_RICH_DASHBOARD' => 'true' })

        result = described_class.get(:SOCIALWISE_RICH_DASHBOARD, account.id)
        expect(result).to be false
      end
    end

    context 'with different flag value formats' do
      it 'handles string "true" as true' do
        allow(GlobalConfig).to receive(:get).with('TEST_FLAG')
                                            .and_return({ 'TEST_FLAG' => 'true' })

        result = described_class.get(:TEST_FLAG)
        expect(result).to be true
      end

      it 'handles string "false" as false' do
        allow(GlobalConfig).to receive(:get).with('TEST_FLAG')
                                            .and_return({ 'TEST_FLAG' => 'false' })

        result = described_class.get(:TEST_FLAG)
        expect(result).to be false
      end

      it 'handles integer 1 as true' do
        allow(GlobalConfig).to receive(:get).with('TEST_FLAG')
                                            .and_return({ 'TEST_FLAG' => 1 })

        result = described_class.get(:TEST_FLAG)
        expect(result).to be true
      end

      it 'handles integer 0 as false' do
        allow(GlobalConfig).to receive(:get).with('TEST_FLAG')
                                            .and_return({ 'TEST_FLAG' => 0 })

        result = described_class.get(:TEST_FLAG)
        expect(result).to be false
      end

      it 'handles empty string as false' do
        allow(GlobalConfig).to receive(:get).with('TEST_FLAG')
                                            .and_return({ 'TEST_FLAG' => '' })

        result = described_class.get(:TEST_FLAG)
        expect(result).to be false
      end

      it 'handles nil as false' do
        allow(GlobalConfig).to receive(:get).with('TEST_FLAG')
                                            .and_return({ 'TEST_FLAG' => nil })

        result = described_class.get(:TEST_FLAG)
        expect(result).to be false
      end
    end
  end

  describe '.enabled_globally?' do
    it 'returns true when global flag is enabled' do
      allow(GlobalConfig).to receive(:get).with('SOCIALWISE_RICH_DASHBOARD')
                                          .and_return({ 'SOCIALWISE_RICH_DASHBOARD' => 'true' })

      result = described_class.enabled_globally?(:SOCIALWISE_RICH_DASHBOARD)
      expect(result).to be true
    end

    it 'returns false when global flag is disabled' do
      allow(GlobalConfig).to receive(:get).with('SOCIALWISE_RICH_DASHBOARD')
                                          .and_return({ 'SOCIALWISE_RICH_DASHBOARD' => nil })

      result = described_class.enabled_globally?(:SOCIALWISE_RICH_DASHBOARD)
      expect(result).to be false
    end
  end

  describe '.enabled_for_account?' do
    it 'returns true when account has flag enabled' do
      AccountFeatureFlag.create!(
        account: account,
        flag_name: 'SOCIALWISE_RICH_DASHBOARD',
        enabled: true
      )

      result = described_class.enabled_for_account?(:SOCIALWISE_RICH_DASHBOARD, account.id)
      expect(result).to be true
    end

    it 'returns false when account has flag disabled' do
      AccountFeatureFlag.create!(
        account: account,
        flag_name: 'SOCIALWISE_RICH_DASHBOARD',
        enabled: false
      )

      result = described_class.enabled_for_account?(:SOCIALWISE_RICH_DASHBOARD, account.id)
      expect(result).to be false
    end

    it 'falls back to global flag when account flag is not set' do
      allow(GlobalConfig).to receive(:get).with('SOCIALWISE_RICH_DASHBOARD')
                                          .and_return({ 'SOCIALWISE_RICH_DASHBOARD' => 'true' })

      result = described_class.enabled_for_account?(:SOCIALWISE_RICH_DASHBOARD, account.id)
      expect(result).to be true
    end
  end

  describe '.set_account_flag' do
    it 'creates new account flag when it does not exist' do
      result = described_class.set_account_flag(:SOCIALWISE_RICH_DASHBOARD, account.id, true)

      expect(result).to be true
      flag = AccountFeatureFlag.find_by(account: account, flag_name: 'SOCIALWISE_RICH_DASHBOARD')
      expect(flag).to be_present
      expect(flag.enabled).to be true
    end

    it 'updates existing account flag' do
      # Create existing flag
      AccountFeatureFlag.create!(
        account: account,
        flag_name: 'SOCIALWISE_RICH_DASHBOARD',
        enabled: false
      )

      result = described_class.set_account_flag(:SOCIALWISE_RICH_DASHBOARD, account.id, true)

      expect(result).to be true
      flag = AccountFeatureFlag.find_by(account: account, flag_name: 'SOCIALWISE_RICH_DASHBOARD')
      expect(flag.enabled).to be true
    end

    it 'clears cache after setting flag' do
      expect(Rails.cache).to receive(:delete).with("feature_flag:account:#{account.id}:SOCIALWISE_RICH_DASHBOARD")

      described_class.set_account_flag(:SOCIALWISE_RICH_DASHBOARD, account.id, true)
    end
  end

  describe '.remove_account_flag' do
    it 'removes existing account flag' do
      # Create existing flag
      AccountFeatureFlag.create!(
        account: account,
        flag_name: 'SOCIALWISE_RICH_DASHBOARD',
        enabled: true
      )

      described_class.remove_account_flag(:SOCIALWISE_RICH_DASHBOARD, account.id)

      flag = AccountFeatureFlag.find_by(account: account, flag_name: 'SOCIALWISE_RICH_DASHBOARD')
      expect(flag).to be_nil
    end

    it 'clears cache after removing flag' do
      expect(Rails.cache).to receive(:delete).with("feature_flag:account:#{account.id}:SOCIALWISE_RICH_DASHBOARD")

      described_class.remove_account_flag(:SOCIALWISE_RICH_DASHBOARD, account.id)
    end

    it 'does not raise error when flag does not exist' do
      expect { described_class.remove_account_flag(:SOCIALWISE_RICH_DASHBOARD, account.id) }.not_to raise_error
    end
  end

  describe '.accounts_with_flag' do
    it 'returns accounts with flag enabled' do
      # Create flags for different accounts
      AccountFeatureFlag.create!(
        account: account,
        flag_name: 'SOCIALWISE_RICH_DASHBOARD',
        enabled: true
      )
      AccountFeatureFlag.create!(
        account: another_account,
        flag_name: 'SOCIALWISE_RICH_DASHBOARD',
        enabled: false
      )

      result = described_class.accounts_with_flag(:SOCIALWISE_RICH_DASHBOARD)
      expect(result).to eq([account.id])
    end

    it 'returns empty array when no accounts have flag enabled' do
      result = described_class.accounts_with_flag(:SOCIALWISE_RICH_DASHBOARD)
      expect(result).to eq([])
    end
  end

  describe 'caching behavior' do
    it 'caches account flag values' do
      AccountFeatureFlag.create!(
        account: account,
        flag_name: 'SOCIALWISE_RICH_DASHBOARD',
        enabled: true
      )

      # First call should hit database
      expect(AccountFeatureFlag).to receive(:find_by).once.and_call_original
      result1 = described_class.get(:SOCIALWISE_RICH_DASHBOARD, account.id)

      # Second call should use cache
      expect(AccountFeatureFlag).not_to receive(:find_by)
      result2 = described_class.get(:SOCIALWISE_RICH_DASHBOARD, account.id)

      expect(result1).to eq(result2)
      expect(result1).to be true
    end

    it 'cache expires after 5 minutes' do
      AccountFeatureFlag.create!(
        account: account,
        flag_name: 'SOCIALWISE_RICH_DASHBOARD',
        enabled: true
      )

      cache_key = "feature_flag:account:#{account.id}:SOCIALWISE_RICH_DASHBOARD"
      expect(Rails.cache).to receive(:fetch).with(cache_key, expires_in: 5.minutes).and_call_original

      described_class.get(:SOCIALWISE_RICH_DASHBOARD, account.id)
    end

    it 'clears all caches' do
      expect(Rails.cache).to receive(:delete_matched).with('feature_flag:*')
      expect(GlobalConfig).to receive(:clear_cache)

      described_class.clear_cache
    end
  end

  describe 'string and symbol handling' do
    it 'handles string flag names' do
      allow(GlobalConfig).to receive(:get).with('SOCIALWISE_RICH_DASHBOARD')
                                          .and_return({ 'SOCIALWISE_RICH_DASHBOARD' => 'true' })

      result = described_class.get('SOCIALWISE_RICH_DASHBOARD')
      expect(result).to be true
    end

    it 'handles symbol flag names' do
      allow(GlobalConfig).to receive(:get).with('SOCIALWISE_RICH_DASHBOARD')
                                          .and_return({ 'SOCIALWISE_RICH_DASHBOARD' => 'true' })

      result = described_class.get(:SOCIALWISE_RICH_DASHBOARD)
      expect(result).to be true
    end
  end
end