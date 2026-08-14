# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountAddon, type: :model do
  let(:account) { create(:account) }
  let(:addon) { create(:addon) }

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:addon) }
  end

  describe 'validations' do
    it 'is valid with a period inside the account package' do
      account_addon = build(:account_addon, account: account, addon: addon)
      expect(account_addon).to be_valid
    end

    it 'requires starts_at and ends_at' do
      account_addon = build(:account_addon, account: account, addon: addon, starts_at: nil)
      expect(account_addon).not_to be_valid

      account_addon = build(:account_addon, account: account, addon: addon, ends_at: nil)
      expect(account_addon).not_to be_valid
    end

    it 'rejects an end date before the start date' do
      account_addon = build(:account_addon, account: account, addon: addon, starts_at: 1.day.from_now, ends_at: 1.day.ago)
      expect(account_addon).not_to be_valid
      expect(account_addon.errors[:ends_at]).to include('must be after starts_at')
    end

    it 'rejects an inactive add-on' do
      inactive = create(:addon, status: :inactive)
      account_addon = build(:account_addon, account: account, addon: inactive)
      expect(account_addon).not_to be_valid
      expect(account_addon.errors[:addon]).to include('is not active and cannot be assigned')
    end

    context 'with a period within the account package' do
      it 'rejects a period that starts before the package start' do
        package_start = account.current_account_package.starts_at
        account_addon = build(:account_addon, account: account, addon: addon,
                                              starts_at: package_start - 1.day, ends_at: package_start + 1.day)
        expect(account_addon).not_to be_valid
        expect(account_addon.errors[:starts_at]).to be_present
      end

      it 'rejects a period that ends after the package end' do
        package_end = account.current_account_package.ends_at
        account_addon = build(:account_addon, account: account, addon: addon,
                                              starts_at: package_end - 1.day, ends_at: package_end + 1.day)
        expect(account_addon).not_to be_valid
        expect(account_addon.errors[:ends_at]).to be_present
      end

      it 'rejects when the account has no current package' do
        account_without_package = create(:account, :without_package)
        account_addon = build(:account_addon, account: account_without_package, addon: addon)
        expect(account_addon).not_to be_valid
        expect(account_addon.errors[:base]).to include('account must have a current active package to add an add-on')
      end
    end

    describe 'duration_type' do
      it 'accepts fixed_months, until_package_end and custom' do
        [
          { duration_type: 'fixed_months', duration_months: 1 },
          { duration_type: 'until_package_end' },
          { duration_type: 'custom' }
        ].each do |attrs|
          account_addon = build(:account_addon, account: account, addon: addon, **attrs)
          expect(account_addon).to be_valid
        end
      end

      it 'rejects an unknown duration_type' do
        account_addon = build(:account_addon, account: account, addon: addon, duration_type: 'quarterly')
        expect(account_addon).not_to be_valid
        expect(account_addon.errors[:duration_type]).to be_present
      end

      it 'requires a positive duration_months for fixed_months' do
        account_addon = build(:account_addon, account: account, addon: addon,
                                              duration_type: 'fixed_months', duration_months: 0)
        expect(account_addon).not_to be_valid
        expect(account_addon.errors[:duration_months]).to be_present
      end
    end
  end

  describe '#resolve_period' do
    it 'resolves a fixed_months end as start + n calendar months (inclusive end of day)' do
      account_addon = described_class.new(
        account: account, addon: addon,
        start_date: Date.new(2026, 8, 14), duration_type: 'fixed_months', duration_months: 3
      )
      account_addon.valid?

      expect(account_addon.starts_at).to eq(Time.zone.local(2026, 8, 14, 0, 0, 0))
      expect(account_addon.ends_at.change(usec: 0)).to eq(Time.zone.local(2026, 11, 14, 23, 59, 59))
    end

    it 'resolves until_package_end to the account package end' do
      package_end = account.current_account_package.ends_at
      account_addon = described_class.new(
        account: account, addon: addon,
        start_date: Date.current, duration_type: 'until_package_end'
      )
      account_addon.valid?

      expect(account_addon.ends_at).to eq(package_end)
    end

    it 'resolves a custom end date to the end of that day' do
      account_addon = described_class.new(
        account: account, addon: addon,
        start_date: Date.new(2026, 8, 14), duration_type: 'custom', end_date: Date.new(2026, 9, 1)
      )
      account_addon.valid?

      expect(account_addon.starts_at).to eq(Time.zone.local(2026, 8, 14, 0, 0, 0))
      expect(account_addon.ends_at.change(usec: 0)).to eq(Time.zone.local(2026, 9, 1, 23, 59, 59))
    end
  end

  describe '#current?' do
    it 'returns true while the period covers now' do
      account_addon = build(:account_addon, account: account, addon: addon, starts_at: 1.day.ago, ends_at: 1.day.from_now)
      expect(account_addon.current?).to be true
    end

    it 'returns false once the period has passed' do
      account_addon = build(:account_addon, account: account, addon: addon, starts_at: 2.days.ago, ends_at: 1.day.ago)
      expect(account_addon.current?).to be false
    end
  end

  describe 'scopes' do
    it '.current returns add-ons whose period covers now' do
      current = create(:account_addon, account: account, addon: addon, starts_at: 1.day.ago, ends_at: 1.day.from_now)
      past = create(:account_addon, account: account, addon: addon, starts_at: 2.days.ago, ends_at: 1.day.ago)

      expect(described_class.current).to include(current)
      expect(described_class.current).not_to include(past)
    end

    it '.with_active_addon returns add-ons whose catalog add-on is active' do
      active = create(:account_addon, account: account, addon: addon)
      inactive_addon = create(:addon, status: :inactive)
      # The model rejects assigning an inactive add-on, so bypass validations to
      # seed a row that exercises the scope filter.
      inactive = build(:account_addon, account: account, addon: inactive_addon)
      inactive.save!(validate: false)

      expect(described_class.with_active_addon).to include(active)
      expect(described_class.with_active_addon).not_to include(inactive)
    end
  end
end
