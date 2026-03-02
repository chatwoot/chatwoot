# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ConversationTriageAgent do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let!(:label1) { create(:label, title: 'billing', account: account) }
  let!(:label2) { create(:label, title: 'technical-support', account: account) }
  let!(:team1) { create(:team, name: 'Support Team', description: 'Handles customer support', account: account) }
  let!(:team2) { create(:team, name: 'Sales Team', description: 'Handles sales inquiries', account: account) }

  let(:available_labels) { [{ 'id' => label1.id, 'title' => 'billing', 'description' => 'Billing related' }] }
  let(:available_teams) { [{ 'id' => team1.id, 'name' => 'Support Team', 'description' => 'Handles customer support' }] }

  let(:conversation_messages) do
    [
      { incoming: true, content: 'Customer message 1' },
      { incoming: false, content: 'Agent response' },
      { incoming: true, content: 'Customer message 2' }
    ]
  end

  before do
    create_list(:message, 3, conversation: conversation, message_type: :incoming, content: 'Customer message')
  end

  describe '.call' do
    context 'when both labels and teams are available' do
      it 'returns suggested label and team IDs' do
        result = described_class.call(
          conversation_messages: conversation_messages,
          available_labels: available_labels,
          available_teams: available_teams,
          dry_run: true,
          account_id: account.id,
          conversation_id: conversation.id,
          inbox_id: conversation.inbox_id
        )

        expect(result).to respond_to(:content)
        expect(result).to respond_to(:success?)
      end
    end

    context 'with dry_run mode' do
      it 'returns prompts without calling API' do
        result = described_class.call(
          conversation_messages: conversation_messages,
          available_labels: available_labels,
          available_teams: available_teams,
          dry_run: true,
          account_id: account.id,
          conversation_id: conversation.id,
          inbox_id: conversation.inbox_id
        )

        expect(result.content[:user_prompt]).to include('Customer message 1')
        expect(result.content[:user_prompt]).to include('billing')
        expect(result.content[:user_prompt]).to include('Support Team')
      end

      it 'includes labels in prompt when available' do
        result = described_class.call(
          conversation_messages: conversation_messages,
          available_labels: available_labels,
          available_teams: [],
          dry_run: true,
          account_id: account.id,
          conversation_id: conversation.id,
          inbox_id: conversation.inbox_id
        )

        expect(result.content[:user_prompt]).to include('billing')
        expect(result.content[:user_prompt]).to include('Billing related')
      end

      it 'includes teams in prompt when available' do
        result = described_class.call(
          conversation_messages: conversation_messages,
          available_labels: [],
          available_teams: available_teams,
          dry_run: true,
          account_id: account.id,
          conversation_id: conversation.id,
          inbox_id: conversation.inbox_id
        )

        expect(result.content[:user_prompt]).to include('Support Team')
        expect(result.content[:user_prompt]).to include('Handles customer support')
      end
    end
  end
end
