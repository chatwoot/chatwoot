require 'rails_helper'

RSpec.describe Captain::InboxPendingConversationsResolutionJob, type: :job do
  let!(:inbox) { create(:inbox) }
  let!(:resolvable_pending_conversation) { create(:conversation, inbox: inbox, last_activity_at: 2.hours.ago, status: :pending) }
  let!(:recent_pending_conversation) { create(:conversation, inbox: inbox, last_activity_at: 1.minute.ago, status: :pending) }
  let!(:open_conversation) { create(:conversation, inbox: inbox, last_activity_at: 1.hour.ago, status: :open) }
  let!(:captain_assistant) { create(:captain_assistant, account: inbox.account) }

  before do
    create(:captain_inbox, inbox: inbox, captain_assistant: captain_assistant)
    stub_const('Limits::BULK_ACTIONS_LIMIT', 3)
    inbox.reload
  end

  it 'queues the job' do
    expect { described_class.perform_later(inbox) }
      .to have_enqueued_job.on_queue('low')
  end

  context 'when captain_tasks is disabled' do
    it 'resolves pending conversations inactive for over 1 hour' do
      described_class.perform_now(inbox)

      expect(resolvable_pending_conversation.reload.status).to eq('resolved')
    end

    it 'does not resolve recent pending conversations' do
      described_class.perform_now(inbox)

      expect(recent_pending_conversation.reload.status).to eq('pending')
    end

    it 'does not affect open conversations' do
      described_class.perform_now(inbox)

      expect(open_conversation.reload.status).to eq('open')
    end

    it 'does not call ConversationCompletionService' do
      allow(Captain::ConversationCompletionService).to receive(:new)

      described_class.perform_now(inbox)

      expect(Captain::ConversationCompletionService).not_to have_received(:new)
    end
  end

  context 'when captain_tasks is enabled' do
    before do
      allow(inbox.account).to receive(:feature_enabled?).and_call_original
      allow(inbox.account).to receive(:feature_enabled?).with('captain_tasks').and_return(true)
    end

    it 'only evaluates eligible pending conversations (inactive > 1 hour)' do
      allow(Captain::ConversationCompletionService).to receive(:new).and_call_original

      # Mock the service to return complete for all conversations
      mock_service = instance_double(Captain::ConversationCompletionService)
      allow(mock_service).to receive(:perform).and_return({ complete: true, reason: 'Test' })
      allow(Captain::ConversationCompletionService).to receive(:new).and_return(mock_service)

      described_class.perform_now(inbox)

      # Only resolvable conversation should be evaluated (not recent or open)
      expect(Captain::ConversationCompletionService).to have_received(:new).with(
        account: inbox.account,
        conversation_display_id: resolvable_pending_conversation.display_id
      )
      expect(recent_pending_conversation.reload.status).to eq('pending')
      expect(open_conversation.reload.status).to eq('open')
    end
  end

  context 'when LLM evaluation returns complete' do
    before do
      allow(inbox.account).to receive(:feature_enabled?).and_call_original
      allow(inbox.account).to receive(:feature_enabled?).with('captain_tasks').and_return(true)
      mock_service = instance_double(Captain::ConversationCompletionService)
      allow(mock_service).to receive(:perform).and_return({ complete: true, reason: 'Customer question was answered' })
      allow(Captain::ConversationCompletionService).to receive(:new).and_return(mock_service)
    end

    it 'resolves the conversation' do
      described_class.perform_now(inbox)

      expect(resolvable_pending_conversation.reload.status).to eq('resolved')
    end

    it 'creates a private note with the reason' do
      described_class.perform_now(inbox)

      private_note = resolvable_pending_conversation.messages.where(private: true).last
      expect(private_note.content).to eq('Auto-resolved: Customer question was answered')
    end

    it 'creates resolution message with configured content' do
      custom_message = 'This is a custom resolution message.'
      captain_assistant.update!(config: { 'resolution_message' => custom_message })
      inbox.reload

      described_class.perform_now(inbox)

      public_message = resolvable_pending_conversation.messages.where(private: false).outgoing.last
      expect(public_message.content).to eq(custom_message)
    end

    it 'creates resolution message with default if not configured' do
      captain_assistant.update!(config: {})
      inbox.reload

      described_class.perform_now(inbox)

      public_message = resolvable_pending_conversation.messages.where(private: false).outgoing.last
      expect(public_message.content).to eq(I18n.t('conversations.activity.auto_resolution_message'))
    end

    it 'adds the correct activity message after resolution' do
      described_class.perform_now(inbox)

      expected_content = I18n.t('conversations.activity.captain.resolved', user_name: captain_assistant.name)
      expect(Conversations::ActivityMessageJob)
        .to have_been_enqueued.with(
          resolvable_pending_conversation,
          {
            account_id: resolvable_pending_conversation.account_id,
            inbox_id: resolvable_pending_conversation.inbox_id,
            message_type: :activity,
            content: expected_content
          }
        )
    end
  end

  context 'when LLM evaluation returns incomplete' do
    let(:handoff_reason) { 'Assistant asked for order number but customer did not respond' }

    before do
      allow(inbox.account).to receive(:feature_enabled?).and_call_original
      allow(inbox.account).to receive(:feature_enabled?).with('captain_tasks').and_return(true)
      mock_service = instance_double(Captain::ConversationCompletionService)
      allow(mock_service).to receive(:perform).and_return({ complete: false, reason: handoff_reason })
      allow(Captain::ConversationCompletionService).to receive(:new).and_return(mock_service)
    end

    it 'hands off the conversation to agents (status becomes open)' do
      described_class.perform_now(inbox)

      expect(resolvable_pending_conversation.reload.status).to eq('open')
    end

    it 'creates a private note with the reason' do
      described_class.perform_now(inbox)

      private_note = resolvable_pending_conversation.messages.where(private: true).last
      expect(private_note.content).to eq("Auto-handoff: #{handoff_reason}")
    end

    it 'creates handoff message with configured content' do
      handoff_message = 'Connecting you to a human agent...'
      captain_assistant.update!(config: { 'handoff_message' => handoff_message })
      inbox.reload
      allow(inbox.account).to receive(:feature_enabled?).and_call_original
      allow(inbox.account).to receive(:feature_enabled?).with('captain_tasks').and_return(true)

      described_class.perform_now(inbox)

      public_message = resolvable_pending_conversation.messages.where(private: false).outgoing.last
      expect(public_message.content).to eq(handoff_message)
    end

    it 'does not create handoff message if not configured' do
      captain_assistant.update!(config: {})
      inbox.reload
      allow(inbox.account).to receive(:feature_enabled?).and_call_original
      allow(inbox.account).to receive(:feature_enabled?).with('captain_tasks').and_return(true)

      expect do
        described_class.perform_now(inbox)
      end.not_to(change { resolvable_pending_conversation.messages.where(private: false).count })
    end
  end

  context 'when LLM evaluation fails' do
    before do
      allow(inbox.account).to receive(:feature_enabled?).and_call_original
      allow(inbox.account).to receive(:feature_enabled?).with('captain_tasks').and_return(true)
      mock_service = instance_double(Captain::ConversationCompletionService)
      allow(mock_service).to receive(:perform).and_return({ complete: false, reason: 'API Error' })
      allow(Captain::ConversationCompletionService).to receive(:new).and_return(mock_service)
    end

    it 'hands off as safe default' do
      described_class.perform_now(inbox)

      expect(resolvable_pending_conversation.reload.status).to eq('open')
    end
  end
end
