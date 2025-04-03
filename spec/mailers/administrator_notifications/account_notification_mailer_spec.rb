require 'rails_helper'
require Rails.root.join 'spec/mailers/administrator_notifications/shared/smtp_config_shared.rb'

RSpec.describe AdministratorNotifications::AccountNotificationMailer do
  include_context 'with smtp config'

  let!(:account) { create(:account) }
  let!(:admin) { create(:user, account: account, role: :administrator) }

  describe 'account_deletion' do
    let(:reason) { 'manual_deletion' }
    let(:mail) { described_class.with(account: account).account_deletion(account, reason) }
    let(:deletion_date) { 7.days.from_now.iso8601 }

    before do
      account.update!(custom_attributes: {
                        'marked_for_deletion_at' => deletion_date,
                        'marked_for_deletion_reason' => reason
                      })
    end

    it 'renders the subject' do
      expect(mail.subject).to eq('Your account has been marked for deletion')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([admin.email])
    end

    it 'includes the account name in the email body' do
      expect(mail.body.encoded).to include(account.name)
    end

    it 'includes the deletion date in the email body' do
      expect(mail.body.encoded).to include(deletion_date)
    end

    it 'includes a link to cancel the deletion' do
      expect(mail.body.encoded).to include('Cancel Account Deletion')
    end

    context 'when reason is manual_deletion' do
      it 'includes the administrator message' do
        expect(mail.body.encoded).to include('This action was requested by one of the administrators of your account')
      end
    end

    context 'when reason is not manual_deletion' do
      let(:reason) { 'inactivity' }

      it 'includes the reason directly' do
        expect(mail.body.encoded).to include('Reason for deletion: inactivity')
      end
    end
  end

  describe 'contact_import_complete' do
    let!(:data_import) { build(:data_import, total_records: 10, processed_records: 8) }
    let(:mail) { described_class.with(account: account).contact_import_complete(data_import).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq('Contact Import Completed')
    end

    it 'renders the processed records' do
      expect(mail.body.encoded).to include('Number of records imported: 8')
      expect(mail.body.encoded).to include('Number of records failed: 2')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([admin.email])
    end
  end

  describe 'contact_import_failed' do
    let(:mail) { described_class.with(account: account).contact_import_failed.deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq('Contact Import Failed')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([admin.email])
    end
  end

  describe 'contact_export_complete' do
    let!(:file_url) { 'http://test.com/test' }
    let(:mail) { described_class.with(account: account).contact_export_complete(file_url, admin.email).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq("Your contact's export file is available to download.")
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([admin.email])
    end
  end

  describe 'automation_rule_disabled' do
    let(:rule) { instance_double(AutomationRule, name: 'Test Rule') }
    let(:mail) { described_class.with(account: account).automation_rule_disabled(rule).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq('Automation rule disabled due to validation errors.')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([admin.email])
    end

    it 'includes the rule name in the email body' do
      expect(mail.body.encoded).to include('Test Rule')
    end
  end
end
