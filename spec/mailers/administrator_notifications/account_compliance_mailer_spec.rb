require 'rails_helper'

RSpec.describe AdministratorNotifications::AccountComplianceMailer, type: :mailer do
  let(:account) do
    create(:account, custom_attributes: { 'marked_for_deletion_at' => 1.day.ago.iso8601, 'marked_for_deletion_reason' => 'user_requested' })
  end

  describe 'account_deleted' do
    it 'has the right subject format' do
      subject = described_class.new.send(:subject_for, account)
      expect(subject).to eq("Account Deletion Notice for #{account.id} - #{account.name}")
    end
  end
end
