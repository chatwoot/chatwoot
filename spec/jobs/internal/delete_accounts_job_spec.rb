require 'rails_helper'

RSpec.describe Internal::DeleteAccountsJob do
  subject(:job) { described_class.perform_later }

  let!(:account_marked_for_deletion) { create(:account) }
  let!(:future_deletion_account) { create(:account) }
  let!(:active_account) { create(:account) }
  let(:account_deletion_service) { instance_double(AccountDeletionService, perform: true) }

  before do
    account_marked_for_deletion.update!(
      custom_attributes: {
        'marked_for_deletion_at' => 1.day.ago.iso8601,
        'marked_for_deletion_reason' => 'user_requested'
      }
    )

    future_deletion_account.update!(
      custom_attributes: {
        'marked_for_deletion_at' => 3.days.from_now.iso8601,
        'marked_for_deletion_reason' => 'user_requested'
      }
    )

    allow(AccountDeletionService).to receive(:new).and_return(account_deletion_service)
  end

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .on_queue('scheduled_jobs')
  end

  describe '#perform' do
    it 'calls AccountDeletionService for accounts past deletion date' do
      described_class.new.perform

      expect(AccountDeletionService).to have_received(:new).with(account: account_marked_for_deletion)
      expect(AccountDeletionService).not_to have_received(:new).with(account: future_deletion_account)
      expect(AccountDeletionService).not_to have_received(:new).with(account: active_account)
      expect(account_deletion_service).to have_received(:perform)
    end
  end
end
