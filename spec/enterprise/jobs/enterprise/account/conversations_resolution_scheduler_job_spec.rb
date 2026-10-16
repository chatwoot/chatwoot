require 'rails_helper'

RSpec.describe Account::ConversationsResolutionSchedulerJob, type: :job do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }

  describe '#perform - captain resolutions' do
    context 'when handling different inbox types' do
      let!(:regular_inbox) { create(:inbox, account: account) }
      let!(:email_inbox) { create(:inbox, :with_email, account: account) }

      before do
        create(:captain_inbox, captain_assistant: assistant, inbox: regular_inbox)
        create(:captain_inbox, captain_assistant: assistant, inbox: email_inbox)
      end

      it 'enqueues resolution jobs only for non-email inboxes with captain enabled' do
        expect do
          described_class.perform_now
        end.to have_enqueued_job(Captain::InboxPendingConversationsResolutionJob)
          .with(regular_inbox)
          .exactly(:once)
      end

      it 'does not enqueue resolution jobs for email inboxes even with captain enabled' do
        expect do
          described_class.perform_now
        end.not_to have_enqueued_job(Captain::InboxPendingConversationsResolutionJob)
          .with(email_inbox)
      end
    end

    context 'when assistant has captain auto resolve disabled' do
      let!(:regular_inbox) { create(:inbox, account: account) }

      before do
        create(:captain_inbox, captain_assistant: assistant, inbox: regular_inbox)
        assistant.update!(auto_resolve_mode: 'disabled')
      end

      it 'does not enqueue resolution jobs' do
        expect do
          described_class.perform_now
        end.not_to have_enqueued_job(Captain::InboxPendingConversationsResolutionJob)
          .with(regular_inbox)
      end
    end

    context 'when account uses legacy disabled settings key' do
      let!(:regular_inbox) { create(:inbox, account: account) }

      before do
        create(:captain_inbox, captain_assistant: assistant, inbox: regular_inbox)
        assistant.update!(config: assistant.config.except('auto_resolve_mode'))
        account.update!(settings: account.settings.merge('captain_disable_auto_resolve' => true))
      end

      it 'does not enqueue resolution jobs' do
        expect do
          described_class.perform_now
        end.not_to have_enqueued_job(Captain::InboxPendingConversationsResolutionJob)
          .with(regular_inbox)
      end
    end

    it 'does not enqueue resolution jobs for inboxes with an external bot' do
      regular_inbox = create(:inbox, account: account)
      create(:captain_inbox, captain_assistant: assistant, inbox: regular_inbox)
      create(:agent_bot_inbox, inbox: regular_inbox, agent_bot: create(:agent_bot, account: account))

      expect do
        described_class.perform_now
      end.not_to have_enqueued_job(Captain::InboxPendingConversationsResolutionJob)
        .with(regular_inbox)
    end

    context 'when an assistant has been deleted before its inbox link is cleaned up' do
      let!(:orphaned_inbox) { create(:inbox, account: account) }
      let!(:regular_inbox) { create(:inbox, account: account) }
      let!(:active_assistant) { create(:captain_assistant, account: account) }

      before do
        create(:captain_inbox, captain_assistant: assistant, inbox: orphaned_inbox)
        create(:captain_inbox, captain_assistant: active_assistant, inbox: regular_inbox)
        assistant.destroy!
      end

      it 'skips the missing assistant and schedules later valid inboxes' do
        expect do
          described_class.perform_now
        end.to have_enqueued_job(Captain::InboxPendingConversationsResolutionJob)
          .with(regular_inbox)
          .exactly(:once)
      end
    end

    context 'when inbox has no captain enabled' do
      let!(:inbox_without_captain) { create(:inbox, account: create(:account)) }

      it 'does not enqueue resolution jobs' do
        expect do
          described_class.perform_now
        end.not_to have_enqueued_job(Captain::InboxPendingConversationsResolutionJob)
          .with(inbox_without_captain)
      end
    end
  end
end
