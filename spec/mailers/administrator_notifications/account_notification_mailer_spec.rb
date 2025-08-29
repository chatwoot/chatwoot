require 'rails_helper'

RSpec.describe AdministratorNotifications::AccountNotificationMailer do
  let(:account) { create(:account, name: 'Test Account') }
  let(:mailer) { described_class.with(account: account) }

  before do
    account.custom_attributes['marked_for_deletion_at'] = 7.days.from_now.iso8601
    account.save!
  end

  describe '#account_deletion_user_initiated' do
    it 'sets the correct subject for user-initiated deletion' do
      mail = mailer.account_deletion_user_initiated(account, 'manual_deletion')
      expect(mail.subject).to eq('Your Chatwoot account deletion has been scheduled')
    end
  end

  describe '#account_deletion_system_initiated' do
    it 'sets the correct subject for system-initiated deletion' do
      mail = mailer.account_deletion_system_initiated(account, 'Account Inactive')
      expect(mail.subject).to eq('Your Chatwoot account is scheduled for deletion due to inactivity')
    end
  end

  describe '#format_deletion_date' do
    it 'formats a valid date string' do
      date_str = '2024-12-31T23:59:59Z'
      formatted = mailer.send(:format_deletion_date, date_str)
      expect(formatted).to eq('December 31, 2024')
    end

    it 'handles blank dates' do
      formatted = mailer.send(:format_deletion_date, nil)
      expect(formatted).to eq('Unknown')
    end

    it 'handles invalid dates' do
      formatted = mailer.send(:format_deletion_date, 'invalid-date')
      expect(formatted).to eq('Unknown')
    end
  end
end
