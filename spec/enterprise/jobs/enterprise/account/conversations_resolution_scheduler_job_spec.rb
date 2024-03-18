require 'rails_helper'

RSpec.describe Account::ConversationsResolutionSchedulerJob, type: :job do
  let!(:account_with_bot) { create(:account) }
  let!(:account_without_bot) { create(:account) }
  let!(:inbox_with_bot) { create(:inbox, account: account_with_bot) }
  let!(:inbox_without_bot) { create(:inbox, account: account_without_bot) }
  let(:response_source) { create(:response_source, account: account_with_bot) }

  before do
    skip_unless_response_bot_enabled_test_environment
    account_with_bot.enable_features!(:response_bot)
    create(:inbox_response_source, inbox: inbox_with_bot, response_source: response_source)
  end

  describe '#perform' do
    it 'enqueues resolution jobs only for inboxes with response bot enabled' do
      expect do
        described_class.perform_now
      end.to have_enqueued_job(ResponseBot::InboxPendingConversationsResolutionJob).with(inbox_with_bot).and have_enqueued_job.exactly(:once)
    end

    it 'does not enqueue resolution jobs for inboxes without response bot enabled' do
      expect do
        described_class.perform_now
      end.not_to have_enqueued_job(ResponseBot::InboxPendingConversationsResolutionJob).with(inbox_without_bot)
    end
  end
end
