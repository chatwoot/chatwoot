require 'rails_helper'

RSpec.describe Internal::InactiveAccountIdentificationService do
  describe '.inactive_accounts' do
    let!(:active_account) { create(:account) }
    let!(:inactive_account) { create(:account, created_at: 60.days.ago) }
    let!(:recently_created_account) { create(:account, created_at: 10.days.ago) }
    let!(:suspended_account) { create(:account, status: :suspended, created_at: 60.days.ago) }
    let!(:marked_for_deletion_account) do
      account = create(:account, created_at: 60.days.ago)
      account.custom_attributes['marked_for_deletion_at'] = 7.days.from_now.iso8601
      account.save!
      account
    end

    let!(:active_user) { create(:user) }
    let!(:inactive_user) { create(:user) }

    before do
      # Set up account users
      create(:account_user, account: active_account, user: active_user, active_at: 5.days.ago)
      create(:account_user, account: inactive_account, user: inactive_user, active_at: 60.days.ago)
      create(:account_user, account: recently_created_account, user: active_user, active_at: nil)
      create(:account_user, account: suspended_account, user: inactive_user, active_at: 60.days.ago)
      create(:account_user, account: marked_for_deletion_account, user: inactive_user, active_at: 60.days.ago)

      # Create conversations for some accounts
      create(:conversation, account: active_account, created_at: 5.days.ago)
      create(:conversation, account: inactive_account, created_at: 60.days.ago)
    end

    it 'identifies only truly inactive accounts' do
      inactive_accounts = described_class.inactive_accounts

      expect(inactive_accounts).to contain_exactly(inactive_account)
    end

    it 'excludes accounts with recent user activity' do
      inactive_accounts = described_class.inactive_accounts

      expect(inactive_accounts).not_to include(active_account)
    end

    it 'excludes recently created accounts' do
      inactive_accounts = described_class.inactive_accounts

      expect(inactive_accounts).not_to include(recently_created_account)
    end

    it 'excludes suspended accounts' do
      inactive_accounts = described_class.inactive_accounts

      expect(inactive_accounts).not_to include(suspended_account)
    end

    it 'excludes accounts already marked for deletion' do
      inactive_accounts = described_class.inactive_accounts

      expect(inactive_accounts).not_to include(marked_for_deletion_account)
    end

    context 'when account has recent conversation activity' do
      before do
        create(:conversation, account: inactive_account, created_at: 5.days.ago)
      end

      it 'excludes accounts with recent conversation activity' do
        inactive_accounts = described_class.inactive_accounts

        expect(inactive_accounts).not_to include(inactive_account)
      end
    end

    context 'when account has updated conversations recently' do
      before do
        conversation = inactive_account.conversations.first
        conversation.update!(updated_at: 5.days.ago)
      end

      it 'excludes accounts with recently updated conversations' do
        inactive_accounts = described_class.inactive_accounts

        expect(inactive_accounts).not_to include(inactive_account)
      end
    end
  end
end