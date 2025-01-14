require 'rails_helper'

RSpec.describe Account::ConversationsResolutionSchedulerJob, type: :job do
  let!(:account_with_bot) { create(:account) }
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account_with_bot) }

  let!(:account_without_bot) { create(:account) }
  let!(:inbox_with_bot) { create(:inbox, account: account_with_bot) }
  let!(:inbox_without_bot) { create(:inbox, account: account_without_bot) }

  describe '#perform - captain resolutions' do
    before do
      create(:captain_inbox, captain_assistant: assistant, inbox: inbox_with_bot)
    end

    it 'enqueues resolution jobs only for inboxes with captain enabled' do
      expect do
        described_class.perform_now
      end.to have_enqueued_job(Captain::InboxPendingConversationsResolutionJob).with(inbox_with_bot).and have_enqueued_job.exactly(:once)
    end

    it 'does not enqueue resolution jobs for inboxes without captain enabled' do
      expect do
        described_class.perform_now
      end.not_to have_enqueued_job(Captain::InboxPendingConversationsResolutionJob).with(inbox_without_bot)
    end
  end
end
