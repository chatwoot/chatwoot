require 'rails_helper'

RSpec.describe Internal::PurgeInactiveAccountsJob do
  describe '#perform' do
    let!(:inactive_account1) { create(:account, created_at: 60.days.ago) }
    let!(:inactive_account2) { create(:account, created_at: 45.days.ago) }
    let!(:active_account) { create(:account) }

    before do
      # Set up inactive accounts
      create(:account_user, account: inactive_account1, user: create(:user), active_at: 60.days.ago)
      create(:account_user, account: inactive_account2, user: create(:user), active_at: 45.days.ago)
      
      # Set up active account
      create(:account_user, account: active_account, user: create(:user), active_at: 5.days.ago)

      # Mock the identification service to return our test accounts
      allow(Internal::InactiveAccountIdentificationService).to receive(:inactive_accounts)
        .and_return(Account.where(id: [inactive_account1.id, inactive_account2.id]))
    end

    it 'marks inactive accounts for deletion' do
      expect { described_class.new.perform }
        .to change { inactive_account1.reload.custom_attributes['marked_for_deletion_at'].present? }
        .from(false).to(true)
        .and change { inactive_account2.reload.custom_attributes['marked_for_deletion_at'].present? }
        .from(false).to(true)
    end

    it 'sets the correct deletion reason' do
      described_class.new.perform

      expect(inactive_account1.reload.custom_attributes['marked_for_deletion_reason']).to eq('Account Inactive')
      expect(inactive_account2.reload.custom_attributes['marked_for_deletion_reason']).to eq('Account Inactive')
    end

    it 'does not affect active accounts' do
      expect { described_class.new.perform }
        .not_to change { active_account.reload.custom_attributes['marked_for_deletion_at'] }
    end

    it 'sends deletion notification emails' do
      expect(AdministratorNotifications::AccountNotificationMailer).to receive(:with)
        .with(account: inactive_account1)
        .and_return(double(account_deletion: double(deliver_later: true)))
      
      expect(AdministratorNotifications::AccountNotificationMailer).to receive(:with)
        .with(account: inactive_account2)
        .and_return(double(account_deletion: double(deliver_later: true)))

      described_class.new.perform
    end

    context 'when no inactive accounts are found' do
      before do
        allow(Internal::InactiveAccountIdentificationService).to receive(:inactive_accounts)
          .and_return(Account.none)
      end

      it 'completes without errors' do
        expect { described_class.new.perform }.not_to raise_error
      end
    end

    context 'when marking an account fails' do
      before do
        allow(inactive_account1).to receive(:mark_for_deletion).and_return(false)
        allow(inactive_account1).to receive(:errors).and_return(double(full_messages: ['Some error']))
        allow(Account).to receive(:where).and_return(double(find_each: [inactive_account1].each))
      end

      it 'continues processing other accounts' do
        expect(Rails.logger).to receive(:error).with(/Failed to mark account/)
        
        described_class.new.perform
      end
    end
  end
end