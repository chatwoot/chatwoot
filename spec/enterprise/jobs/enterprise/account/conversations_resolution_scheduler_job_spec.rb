require 'rails_helper'

RSpec.describe Account::ConversationsResolutionSchedulerJob, type: :job do
  let(:account) { create(:account) }
  let(:topic) { create(:aiagent_topic, account: account) }

  describe '#perform - aiagent resolutions' do
    context 'when handling different inbox types' do
      let!(:regular_inbox) { create(:inbox, account: account) }
      let!(:email_inbox) { create(:inbox, :with_email, account: account) }

      before do
        create(:aiagent_inbox, aiagent_topic: topic, inbox: regular_inbox)
        create(:aiagent_inbox, aiagent_topic: topic, inbox: email_inbox)
      end

      it 'enqueues resolution jobs only for non-email inboxes with aiagent enabled' do
        expect do
          described_class.perform_now
        end.to have_enqueued_job(Aiagent::InboxPendingConversationsResolutionJob)
          .with(regular_inbox)
          .exactly(:once)
      end

      it 'does not enqueue resolution jobs for email inboxes even with aiagent enabled' do
        expect do
          described_class.perform_now
        end.not_to have_enqueued_job(Aiagent::InboxPendingConversationsResolutionJob)
          .with(email_inbox)
      end
    end

    context 'when inbox has no aiagent enabled' do
      let!(:inbox_without_aiagent) { create(:inbox, account: create(:account)) }

      it 'does not enqueue resolution jobs' do
        expect do
          described_class.perform_now
        end.not_to have_enqueued_job(Aiagent::InboxPendingConversationsResolutionJob)
          .with(inbox_without_aiagent)
      end
    end
  end
end
