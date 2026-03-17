require 'rails_helper'

RSpec.describe Captain::Tools::ResolveConversationTool do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :open) }
  let(:tool) { described_class.new(assistant) }
  let(:tool_context) { Struct.new(:state).new({ conversation: { id: conversation.id } }) }

  before do
    Current.executed_by = assistant
  end

  after do
    Current.reset
  end

  describe 'resolving a conversation' do
    it 'marks resolved and enqueues an activity message with the reason' do
      tool.perform(tool_context, reason: 'Possible spam')

      expect(conversation.reload).to be_resolved
      expect(Conversations::ActivityMessageJob).to have_been_enqueued.with(
        conversation,
        hash_including(
          content: I18n.t('conversations.activity.captain.resolved_by_tool', user_name: assistant.name, reason: 'Possible spam')
        )
      )
    end

    it 'creates a conversation_resolved reporting event' do
      create(:captain_inbox, captain_assistant: assistant, inbox: inbox)

      expect do
        perform_enqueued_jobs do
          tool.perform(tool_context, reason: 'Possible spam')
        end
      end.to change { ReportingEvent.where(conversation_id: conversation.id, name: 'conversation_resolved').count }.by(1)
    end
  end

  describe 'when auto-resolve is disabled for the account' do
    before { account.update!(captain_auto_resolve_mode: 'disabled') }

    it 'does not resolve and returns a disabled message' do
      result = tool.perform(tool_context, reason: 'Possible spam')

      expect(result).to eq('Auto-resolve is disabled for this account')
      expect(conversation.reload).not_to be_resolved
    end
  end

  describe 'when auto-resolve is disabled via legacy settings key' do
    before { account.update!(settings: account.settings.merge('captain_disable_auto_resolve' => true)) }

    it 'does not resolve and returns a disabled message' do
      result = tool.perform(tool_context, reason: 'Possible spam')

      expect(result).to eq('Auto-resolve is disabled for this account')
      expect(conversation.reload).not_to be_resolved
    end
  end

  describe 'resolving an already resolved conversation' do
    let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :resolved) }

    it 'does not re-resolve and returns an already resolved message' do
      queue_adapter = ActiveJob::Base.queue_adapter
      queue_adapter.enqueued_jobs.clear

      result = tool.perform(tool_context, reason: 'Possible spam')

      expect(result).to include('already resolved')
      expect(Conversations::ActivityMessageJob).not_to have_been_enqueued
    end
  end
end
