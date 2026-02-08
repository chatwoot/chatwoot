# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountFeatureFlag do
  let(:account) { create(:account) }
  let(:another_account) { create(:account) }

  describe 'validations' do
    it 'validates presence of flag_name' do
      flag = described_class.new(account: account, enabled: true)
      expect(flag).not_to be_valid
      expect(flag.errors[:flag_name]).to include("can't be blank")
    end

    it 'validates uniqueness of flag_name scoped to account' do
      described_class.create!(
        account: account,
        flag_name: 'SOCIALWISE_RICH_DASHBOARD',
        enabled: true
      )

      duplicate_flag = described_class.new(
        account: account,
        flag_name: 'SOCIALWISE_RICH_DASHBOARD',
        enabled: false
      )

      expect(duplicate_flag).not_to be_valid
      expect(duplicate_flag.errors[:flag_name]).to include('has already been taken')
    end

    it 'allows same flag_name for different accounts' do
      described_class.create!(
        account: account,
        flag_name: 'SOCIALWISE_RICH_DASHBOARD',
        enabled: true
      )

      different_account_flag = described_class.new(
        account: another_account,
        flag_name: 'SOCIALWISE_RICH_DASHBOARD',
        enabled: false
      )

      expect(different_account_flag).to be_valid
    end

    it 'validates enabled is boolean' do
      flag = described_class.new(
        account: account,
        flag_name: 'SOCIALWISE_RICH_DASHBOARD',
        enabled: 'invalid'
      )

      expect(flag).not_to be_valid
      expect(flag.errors[:enabled]).to include('is not included in the list')
    end

    it 'validates flag_name is supported' do
      flag = described_class.new(
        account: account,
        flag_name: 'UNSUPPORTED_FLAG',
        enabled: true
      )

      expect(flag).not_to be_valid
      expect(flag.errors[:flag_name]).to include('is not a supported feature flag')
    end

    it 'allows supported flag names' do
      flag = described_class.new(
        account: account,
        flag_name: 'SOCIALWISE_RICH_DASHBOARD',
        enabled: true
      )

      expect(flag).to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to account' do
      flag = described_class.create!(
        account: account,
        flag_name: 'SOCIALWISE_RICH_DASHBOARD',
        enabled: true
      )

      expect(flag.account).to eq(account)
    end
  end

  describe 'scopes' do
    before do
      described_class.create!(
        account: account,
        flag_name: 'SOCIALWISE_RICH_DASHBOARD',
        enabled: true
      )
      described_class.create!(
        account: another_account,
        flag_name: 'SOCIALWISE_RICH_DASHBOARD',
        enabled: false
      )
    end

    describe '.enabled' do
      it 'returns only enabled flags' do
        enabled_flags = described_class.enabled
        expect(enabled_flags.count).to eq(1)
        expect(enabled_flags.first.account).to eq(account)
      end
    end

    describe '.disabled' do
      it 'returns only disabled flags' do
        disabled_flags = described_class.disabled
        expect(disabled_flags.count).to eq(1)
        expect(disabled_flags.first.account).to eq(another_account)
      end
    end

    describe '.for_flag' do
      it 'returns flags for specific flag name' do
        flags = described_class.for_flag('SOCIALWISE_RICH_DASHBOARD')
        expect(flags.count).to eq(2)
      end

      it 'works with symbol flag names' do
        flags = described_class.for_flag(:SOCIALWISE_RICH_DASHBOARD)
        expect(flags.count).to eq(2)
      end
    end
  end

  describe '.enabled_for_account?' do
    it 'returns true when account has flag enabled' do
      described_class.create!(
        account: account,
        flag_name: 'SOCIALWISE_RICH_DASHBOARD',
        enabled: true
      )

      result = described_class.enabled_for_account?('SOCIALWISE_RICH_DASHBOARD', account.id)
      expect(result).to be true
    end

    it 'returns false when account has flag disabled' do
      described_class.create!(
        account: account,
        flag_name: 'SOCIALWISE_RICH_DASHBOARD',
        enabled: false
      )

      result = described_class.enabled_for_account?('SOCIALWISE_RICH_DASHBOARD', account.id)
      expect(result).to be false
    end

    it 'returns false when account has no flag' do
      result = described_class.enabled_for_account?('SOCIALWISE_RICH_DASHBOARD', account.id)
      expect(result).to be false
    end

    it 'works with symbol flag names' do
      described_class.create!(
        account: account,
        flag_name: 'SOCIALWISE_RICH_DASHBOARD',
        enabled: true
      )

      result = described_class.enabled_for_account?(:SOCIALWISE_RICH_DASHBOARD, account.id)
      expect(result).to be true
    end
  end

  describe '.enabled_flags_for_account' do
    it 'returns enabled flag names for account' do
      described_class.create!(
        account: account,
        flag_name: 'SOCIALWISE_RICH_DASHBOARD',
        enabled: true
      )

      result = described_class.enabled_flags_for_account(account.id)
      expect(result).to eq(['SOCIALWISE_RICH_DASHBOARD'])
    end

    it 'returns empty array when no flags are enabled' do
      described_class.create!(
        account: account,
        flag_name: 'SOCIALWISE_RICH_DASHBOARD',
        enabled: false
      )

      result = described_class.enabled_flags_for_account(account.id)
      expect(result).to eq([])
    end
  end

  describe '.accounts_with_flag_enabled' do
    it 'returns accounts with flag enabled' do
      described_class.create!(
        account: account,
        flag_name: 'SOCIALWISE_RICH_DASHBOARD',
        enabled: true
      )
      described_class.create!(
        account: another_account,
        flag_name: 'SOCIALWISE_RICH_DASHBOARD',
        enabled: false
      )

      result = described_class.accounts_with_flag_enabled('SOCIALWISE_RICH_DASHBOARD')
      expect(result).to include(account)
      expect(result).not_to include(another_account)
    end

    it 'works with symbol flag names' do
      described_class.create!(
        account: account,
        flag_name: 'SOCIALWISE_RICH_DASHBOARD',
        enabled: true
      )

      result = described_class.accounts_with_flag_enabled(:SOCIALWISE_RICH_DASHBOARD)
      expect(result).to include(account)
    end
  end

  describe '.bulk_enable' do
    it 'enables flag for multiple accounts' do
      account_ids = [account.id, another_account.id]

      described_class.bulk_enable('SOCIALWISE_RICH_DASHBOARD', account_ids)

      account_ids.each do |account_id|
        flag = described_class.find_by(account_id: account_id, flag_name: 'SOCIALWISE_RICH_DASHBOARD')
        expect(flag).to be_present
        expect(flag.enabled).to be true
      end
    end

    it 'clears cache for affected accounts' do
      account_ids = [account.id, another_account.id]

      account_ids.each do |account_id|
        expect(Rails.cache).to receive(:delete).with("feature_flag:account:#{account_id}:SOCIALWISE_RICH_DASHBOARD")
      end

      described_class.bulk_enable('SOCIALWISE_RICH_DASHBOARD', account_ids)
    end
  end

  describe '.bulk_disable' do
    before do
      described_class.create!(
        account: account,
        flag_name: 'SOCIALWISE_RICH_DASHBOARD',
        enabled: true
      )
      described_class.create!(
        account: another_account,
        flag_name: 'SOCIALWISE_RICH_DASHBOARD',
        enabled: true
      )
    end

    it 'disables flag for multiple accounts' do
      account_ids = [account.id, another_account.id]

      described_class.bulk_disable('SOCIALWISE_RICH_DASHBOARD', account_ids)

      account_ids.each do |account_id|
        flag = described_class.find_by(account_id: account_id, flag_name: 'SOCIALWISE_RICH_DASHBOARD')
        expect(flag.enabled).to be false
      end
    end

    it 'clears cache for affected accounts' do
      account_ids = [account.id, another_account.id]

      account_ids.each do |account_id|
        expect(Rails.cache).to receive(:delete).with("feature_flag:account:#{account_id}:SOCIALWISE_RICH_DASHBOARD")
      end

      described_class.bulk_disable('SOCIALWISE_RICH_DASHBOARD', account_ids)
    end
  end

  describe 'cache clearing' do
    it 'clears cache after create' do
      expect(Rails.cache).to receive(:delete).with("feature_flag:account:#{account.id}:SOCIALWISE_RICH_DASHBOARD")

      described_class.create!(
        account: account,
        flag_name: 'SOCIALWISE_RICH_DASHBOARD',
        enabled: true
      )
    end

    it 'clears cache after update' do
      flag = described_class.create!(
        account: account,
        flag_name: 'SOCIALWISE_RICH_DASHBOARD',
        enabled: false
      )

      expect(Rails.cache).to receive(:delete).with("feature_flag:account:#{account.id}:SOCIALWISE_RICH_DASHBOARD")

      flag.update!(enabled: true)
    end

    it 'clears cache after destroy' do
      flag = described_class.create!(
        account: account,
        flag_name: 'SOCIALWISE_RICH_DASHBOARD',
        enabled: true
      )

      expect(Rails.cache).to receive(:delete).with("feature_flag:account:#{account.id}:SOCIALWISE_RICH_DASHBOARD")

      flag.destroy!
    end
  end

  describe 'constants' do
    it 'defines supported flags' do
      expect(described_class::SUPPORTED_FLAGS).to include('SOCIALWISE_RICH_DASHBOARD')
    end
  end
end