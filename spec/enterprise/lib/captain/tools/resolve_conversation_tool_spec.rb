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

    it 'clears captain_resolve_reason after execution' do
      tool.perform(tool_context, reason: 'Possible spam')

      expect(Current.captain_resolve_reason).to be_nil
    end

    it 'dispatches resolved event with assistant source' do
      allow(Rails.configuration.dispatcher).to receive(:dispatch).and_call_original

      tool.perform(tool_context, reason: 'Possible spam')

      expect(Rails.configuration.dispatcher).to have_received(:dispatch).with(
        'conversation.resolved',
        anything,
        hash_including(captain_action_source: 'assistant')
      )
    end

    it 'creates a conversation_resolved reporting event with assistant source' do
      create(:captain_inbox, captain_assistant: assistant, inbox: inbox)

      expect do
        perform_enqueued_jobs do
          tool.perform(tool_context, reason: 'Possible spam')
        end
      end.to change { ReportingEvent.where(conversation_id: conversation.id, name: 'conversation_resolved').count }.by(1)

      reporting_event = ReportingEvent.find_by(conversation_id: conversation.id, name: 'conversation_resolved')
      expect(reporting_event.source).to eq('assistant')
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
