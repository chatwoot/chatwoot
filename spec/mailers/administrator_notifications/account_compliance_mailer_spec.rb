require 'rails_helper'

RSpec.describe AdministratorNotifications::AccountComplianceMailer, type: :mailer do
  let(:account) do
    create(:account, custom_attributes: { 'marked_for_deletion_at' => 1.day.ago.iso8601, 'marked_for_deletion_reason' => 'user_requested' })
  end
  let(:soft_deleted_users) do
    [
      { id: 1, original_email: 'user1@example.com', new_email: 'user1@example.com-deleted.com' },
      { id: 2, original_email: 'user2@example.com', new_email: 'user2@example.com-deleted.com' }
    ]
  end

  describe 'account_deleted' do
    it 'has the right subject format' do
      subject = described_class.new.send(:subject_for, account)
      expect(subject).to eq("Account Deletion Notice for #{account.id} - #{account.name}")
    end

    it 'includes soft deleted users in meta when provided' do
      allow_any_instance_of(described_class).to receive(:params).and_return(
        { soft_deleted_users: soft_deleted_users }
      )

      mailer_instance = described_class.new
      meta = mailer_instance.send(:build_meta, account)

      expect(meta['soft_deleted_users']).to eq(soft_deleted_users)
    end
  end
end
