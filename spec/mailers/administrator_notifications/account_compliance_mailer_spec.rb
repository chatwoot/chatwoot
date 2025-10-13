require 'rails_helper'

RSpec.describe AdministratorNotifications::AccountComplianceMailer do
  let(:account) do
    create(:account, custom_attributes: { 'marked_for_deletion_at' => 1.day.ago.iso8601, 'marked_for_deletion_reason' => 'user_requested' })
  end
  let(:soft_deleted_users) do
    [
      { id: 1, original_email: 'user1@example.com' },
      { id: 2, original_email: 'user2@example.com' }
    ]
  end

  describe 'account_deleted' do
    it 'has the right subject format' do
      subject = described_class.new.send(:subject_for, account)
      expect(subject).to eq("Account Deletion Notice for #{account.id} - #{account.name}")
    end

    it 'includes soft deleted users in meta when provided' do
      mailer_instance = described_class.new
      allow(mailer_instance).to receive(:params).and_return(
        { soft_deleted_users: soft_deleted_users }
      )

      meta = mailer_instance.send(:build_meta, account)

      expect(meta['deleted_user_count']).to eq(2)
      expect(meta['soft_deleted_users'].size).to eq(2)
      expect(meta['soft_deleted_users'].first['user_id']).to eq('1')
      expect(meta['soft_deleted_users'].first['user_email']).to eq('user1@example.com')
    end
  end
end
