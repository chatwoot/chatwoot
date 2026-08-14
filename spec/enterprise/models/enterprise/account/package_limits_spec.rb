# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Account do
  describe 'Enterprise::Account::PackageLimits' do
    let(:account) { create(:account, :without_package) }
    let(:package) do
      create(:package,
             users_limit: 5,
             channels_limit: 3,
             contacts_limit: 100,
             conversations_limit: 50,
             campaign_messages_limit: 200)
    end

    describe '#usage_limits' do
      context 'without a package assignment' do
        it 'falls back to the enterprise base limits' do
          base = account.usage_limits

          expect(base[:agents]).to eq(ChatwootApp.max_limit)
          expect(base[:inboxes]).to eq(ChatwootApp.max_limit)
          expect(base[:captain]).to be_present
          expect(base[:contacts]).to be_nil
          expect(base[:conversations]).to be_nil
          expect(base[:campaign_messages]).to be_nil
        end
      end

      context 'with a package assignment' do
        before { create(:account_package, account: account, package: package) }

        it 'overrides each of the package limit keys' do
          limits = account.usage_limits

          expect(limits[:agents]).to eq(5)               # users_limit
          expect(limits[:inboxes]).to eq(3)              # channels_limit
          expect(limits[:contacts]).to eq(100)           # contacts_limit
          expect(limits[:conversations]).to eq(50)       # conversations_limit
          expect(limits[:campaign_messages]).to eq(200)  # campaign_messages_limit
        end

        it 'preserves the captain limits' do
          expect(account.usage_limits[:captain]).to be_present
        end

        it 'falls back to base limits when a package limit is nil' do
          base_agents = create(:account, :without_package).usage_limits[:agents]
          package.update!(users_limit: nil)

          expect(account.usage_limits[:agents]).to eq(base_agents)
        end
      end

      context 'with an account add-on boost' do
        let(:addon) { create(:addon, users_limit: 100, channels_limit: 20, contacts_limit: 1000) }

        before do
          create(:account_package, account: account, package: package)
          create(:account_addon, account: account, addon: addon,
                                 starts_at: 1.day.ago, ends_at: 1.day.from_now)
        end

        it 'adds the add-on boosts to the package limits' do
          limits = account.usage_limits

          expect(limits[:agents]).to eq(105)             # 5 + 100
          expect(limits[:inboxes]).to eq(23)             # 3 + 20
          expect(limits[:contacts]).to eq(1100)          # 100 + 1000
          expect(limits[:conversations]).to eq(50)       # no conversation boost
          expect(limits[:campaign_messages]).to eq(200)  # no campaign boost
        end

        it 'does not count an add-on whose period has expired' do
          create(:account_addon, account: account, addon: addon, starts_at: 2.days.ago, ends_at: 1.day.ago)

          expect(account.usage_limits[:agents]).to eq(105)  # only the current one counts
        end

        it 'does not count an add-on that is no longer active' do
          addon.update!(status: :inactive)

          expect(account.usage_limits[:agents]).to eq(5)
        end

        it 'does not count an add-on whose period falls outside the package period' do
          # Current period but starting before the package start — the model would
          # reject it, so build it as a legacy/edge-case row to exercise the
          # package-period clamp in active_addons.
          outside = build(:account_addon, account: account, addon: addon,
                                          starts_at: 2.months.ago, ends_at: 1.month.from_now)
          outside.save!(validate: false)

          expect(account.usage_limits[:agents]).to eq(105)
        end
      end
    end

    describe '#active?' do
      it 'is inactive without a package' do
        expect(account).not_to be_active
      end

      it 'is active with a current active package' do
        create(:account_package, account: account, package: package)

        expect(account).to be_active
      end

      it 'is inactive when the package is set inactive' do
        package.update!(status: :inactive)
        create(:account_package, account: account, package: package)

        expect(account).not_to be_active
      end

      it 'is inactive after the package expires' do
        create(:account_package, account: account, package: package, starts_at: 2.days.ago, ends_at: 1.day.ago)

        expect(account).not_to be_active
      end

      it 'is inactive before a future-dated package starts' do
        create(:account_package, account: account, package: package, starts_at: 1.day.from_now, ends_at: 2.days.from_now)

        expect(account).not_to be_active
      end
    end

    describe '#package_usage_window' do
      it 'returns nil without a package' do
        expect(account.package_usage_window).to be_nil
      end

      it 'returns the month-bucket anchored at the assignment start date' do
        travel_to(Time.zone.local(2026, 8, 20)) do
          create(:account_package, account: account, package: package, starts_at: Time.zone.local(2026, 5, 15))

          window = account.package_usage_window
          expect(window[0]).to eq(Time.zone.local(2026, 8, 15))
          expect(window[1]).to eq(Time.zone.local(2026, 9, 15))
        end
      end

      it 'moves to the previous bucket before the anchor day of the month' do
        travel_to(Time.zone.local(2026, 8, 10)) do
          create(:account_package, account: account, package: package, starts_at: Time.zone.local(2026, 5, 15))

          window = account.package_usage_window
          expect(window[0]).to eq(Time.zone.local(2026, 7, 15))
          expect(window[1]).to eq(Time.zone.local(2026, 8, 15))
        end
      end
    end
  end
end
