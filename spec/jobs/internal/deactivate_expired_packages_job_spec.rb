# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Internal::DeactivateExpiredPackagesJob, type: :job do
  it 'suspends active accounts that never had a package' do
    account = create(:account, :without_package)

    described_class.perform_now

    expect(account.reload).to be_suspended
  end

  it 'suspends accounts whose package has expired' do
    account = create(:account, :without_package)
    create(:account_package, account: account, starts_at: 2.days.ago, ends_at: 1.day.from_now)
    expect(account.reload).to be_active

    travel_to(2.days.from_now) do
      described_class.perform_now
      expect(account.reload).to be_suspended
    end
  end

  it 'leaves accounts with a current active package active' do
    account = create(:account, :without_package)
    create(:account_package, account: account, starts_at: 1.day.ago, ends_at: 1.day.from_now)

    described_class.perform_now

    expect(account.reload).to be_active
  end

  it 'leaves accounts with a future-dated package suspended' do
    account = create(:account, :without_package, status: :suspended)
    create(:account_package, account: account, starts_at: 1.day.from_now, ends_at: 2.days.from_now)

    described_class.perform_now

    expect(account.reload).to be_suspended
  end
end
