# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountPackage do
  let(:account) { create(:account, :without_package, status: :suspended) }
  let(:package) { create(:package) }

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:package) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:starts_at) }
    it { is_expected.to validate_presence_of(:ends_at) }

    it 'rejects an end date not after the start date' do
      assignment = build(:account_package, account: account, package: package, starts_at: 1.day.from_now, ends_at: Time.current)

      expect(assignment).not_to be_valid
      expect(assignment.errors[:ends_at]).to include('must be after starts_at')
    end

    it 'accepts an end date after the start date' do
      expect(build(:account_package, account: account, package: package)).to be_valid
    end
  end

  describe 'status sync' do
    it 'activates the account when a current active package is assigned' do
      expect { create(:account_package, account: account, package: package) }
        .to change { account.reload.status }.from('suspended').to('active')
    end

    it 'keeps the account inactive for a future-dated assignment' do
      create(:account_package, account: account, package: package, starts_at: 1.day.from_now, ends_at: 2.days.from_now)

      expect(account.reload).to be_suspended
    end

    it 'keeps the account inactive when the package is inactive' do
      package.update!(status: :inactive)
      create(:account_package, account: account, package: package)

      expect(account.reload).to be_suspended
    end

    it 'suspends the account when the assignment is removed' do
      assignment = create(:account_package, account: account, package: package)
      expect(account.reload).to be_active

      expect { assignment.destroy }.to change { account.reload.status }.from('active').to('suspended')
    end

    it 'does not raise when the account is already destroyed' do
      assignment = create(:account_package, account: account, package: package)
      account.destroy

      expect { assignment.destroy }.not_to raise_error
    end
  end

  describe '.current' do
    it 'includes only assignments that are active right now' do
      current = create(:account_package, account: account, package: package, starts_at: 1.day.ago, ends_at: 1.day.from_now)
      create(:account_package, account: account, package: package, starts_at: 2.days.ago, ends_at: 1.day.ago)

      expect(AccountPackage.current).to contain_exactly(current)
    end
  end
end
