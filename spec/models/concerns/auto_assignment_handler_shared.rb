# frozen_string_literal: true

require 'rails_helper'

shared_examples_for 'auto_assignment_handler' do
  describe '#auto assignment' do
    let(:account) { create(:account) }
    let(:agent) { create(:user, email: 'agent1@example.com', account: account, auto_offline: false) }
    let(:inbox) { create(:inbox, account: account) }
    let(:conversation) do
      create(
        :conversation,
        account: account,
        contact: create(:contact, account: account),
        inbox: inbox,
        assignee: nil
      )
    end

    before do
      create(:inbox_member, inbox: inbox, user: agent)
      allow(Redis::Alfred).to receive(:rpoplpush).and_return(agent.id)
    end

    it 'runs round robin on after_save callbacks' do
      expect(conversation.reload.assignee).to eq(agent)
    end

    it 'will not auto assign agent if enable_auto_assignment is false' do
      inbox.update(enable_auto_assignment: false)

      expect(conversation.reload.assignee).to be_nil
    end

    it 'will not auto assign agent if its a bot conversation' do
      conversation = create(
        :conversation,
        account: account,
        contact: create(:contact, account: account),
        inbox: inbox,
        status: 'pending',
        assignee: nil
      )

      expect(conversation.reload.assignee).to be_nil
    end

    it 'keeps AgentBot ownership when the conversation opens' do
      agent_bot = create(:agent_bot, account: account)
      conversation = create(:conversation, account: account, inbox: inbox, status: 'pending', ai_assignee: agent_bot)

      conversation.update!(status: 'open')

      expect(conversation.reload.assigned_entity).to eq(agent_bot)
    end

    it 'assigns an agent when bot handoff clears the agent bot in the same save' do
      agent_bot = create(:agent_bot, account: account)
      handoff_conversation = create(:conversation, account: account, inbox: inbox, status: 'pending', ai_assignee: agent_bot)

      handoff_conversation.bot_handoff!

      expect(handoff_conversation.reload.assignee).to eq(agent)
      expect(handoff_conversation.ai_assignee).to be_nil
    end

    it 'emits conversation.opened when auto assignment runs on the open transition' do
      conversation.update!(status: 'pending', assignee: nil)
      allow(Rails.configuration.dispatcher).to receive(:dispatch)

      conversation.update!(status: 'open')

      expect(conversation.assignee).to eq(agent)
      expect(conversation.previous_changes.keys).to include('status', 'assignee_id')
      expect(Rails.configuration.dispatcher).to have_received(:dispatch)
        .with(described_class::CONVERSATION_OPENED, kind_of(Time), hash_including(conversation: conversation))
      expect(Rails.configuration.dispatcher).to have_received(:dispatch)
        .with(described_class::ASSIGNEE_CHANGED, kind_of(Time), hash_including(conversation: conversation))
    end

    it 'does not re-announce an open transition a concurrent request already committed' do
      conversation.update!(status: 'pending', assignee: nil)
      stale = Conversation.find(conversation.id)
      conversation.update!(status: 'open')
      allow(Rails.configuration.dispatcher).to receive(:dispatch)

      stale.update!(status: 'open')

      expect(stale.reload.assignee).to eq(agent)
      expect(Rails.configuration.dispatcher).not_to have_received(:dispatch)
    end

    it 'still assigns on a stale open transition when the earlier open found no agent' do
      allow(Redis::Alfred).to receive(:rpoplpush).and_return(nil)
      conversation.update!(status: 'pending', assignee: nil)
      stale = Conversation.find(conversation.id)
      conversation.update!(status: 'open')
      allow(Redis::Alfred).to receive(:rpoplpush).and_return(agent.id)
      allow(Rails.configuration.dispatcher).to receive(:dispatch)

      stale.update!(status: 'open')

      expect(stale.reload.assignee).to eq(agent)
      expect(Rails.configuration.dispatcher).not_to have_received(:dispatch)
        .with(described_class::CONVERSATION_OPENED, kind_of(Time), hash_including(conversation: stale))
    end

    it 'gets triggered on update only when status changes to open' do
      conversation.status = 'resolved'
      conversation.save!
      expect(conversation.reload.assignee).to eq(agent)
      inbox.inbox_members.where(user_id: agent.id).first.destroy!

      # round robin changes assignee in this case since agent doesn't have access to inbox
      agent2 = create(:user, email: 'agent2@example.com', account: account, auto_offline: false)
      create(:inbox_member, inbox: inbox, user: agent2)
      allow(Redis::Alfred).to receive(:rpoplpush).and_return(agent2.id)
      conversation.status = 'open'
      conversation.save!
      expect(conversation.reload.assignee).to eq(agent2)
    end
  end
end
