# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Aloo Handoff Workflow', type: :integration do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let(:assistant) { create(:aloo_assistant, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :pending) }
  let(:agent) { create(:user, account: account, role: :agent) }

  before do
    create(:aloo_assistant_inbox, assistant: assistant, inbox: inbox)
    create(:inbox_member, inbox: inbox, user: agent)
  end

  describe 'handoff initiation' do
    let(:handoff_tool_call) { instance_double('RubyLLM::ToolCall', name: 'handoff') }
    let(:agent_result) do
      instance_double(
        'RubyLLM::Agents::Result',
        success?: true,
        content: 'Let me transfer you to a human agent.',
        input_tokens: 100,
        output_tokens: 50,
        tool_calls: [handoff_tool_call]
      )
    end

    before do
      allow(RubyLLM).to receive(:embed).and_return(
        instance_double('RubyLLM::Embedding', vectors: Array.new(1536) { 0.0 })
      )
      allow(ConversationAgent).to receive(:call).and_return(agent_result)
    end

    it 'does not send AI response after handoff' do
      message = create(:message, conversation: conversation, message_type: :incoming, content: 'I want to speak to a human')
      event = Events::Base.new('message.created', Time.zone.now, message: message)

      expect {
        perform_enqueued_jobs do
          AlooAgentListener.instance.message_created(event)
        end
      }.not_to change { conversation.messages.where(sender_type: 'Aloo::Assistant').count }
    end

    it 'updates conversation status to open' do
      message = create(:message, conversation: conversation, message_type: :incoming, content: 'I need human help')
      event = Events::Base.new('message.created', Time.zone.now, message: message)

      perform_enqueued_jobs do
        AlooAgentListener.instance.message_created(event)
      end

      expect(conversation.reload.status).to eq('open')
    end
  end

  describe 'handoff flag management' do
    context 'when handoff is active' do
      before do
        conversation.update!(custom_attributes: { 'aloo_handoff_active' => true })
      end

      it 'blocks AI responses when handoff active' do
        allow(ConversationAgent).to receive(:call)

        message = create(:message, conversation: conversation, message_type: :incoming, content: 'Hello')
        event = Events::Base.new('message.created', Time.zone.now, message: message)

        expect(Aloo::ResponseJob).not_to receive(:perform_later)

        AlooAgentListener.instance.message_created(event)
      end

      it 'clears handoff flag when conversation reopened' do
        event = Events::Base.new(
          'conversation.status_changed',
          Time.zone.now,
          conversation: conversation,
          changed_attributes: { 'status' => %w[resolved open] }
        )

        AlooAgentListener.instance.conversation_status_changed(event)

        expect(conversation.reload.custom_attributes['aloo_handoff_active']).to be false
      end

      it 'allows AI responses after handoff cleared' do
        # First, clear the handoff
        clear_event = Events::Base.new(
          'conversation.status_changed',
          Time.zone.now,
          conversation: conversation,
          changed_attributes: { 'status' => %w[resolved open] }
        )
        AlooAgentListener.instance.conversation_status_changed(clear_event)

        # Now, new message should trigger response
        agent_result = instance_double(
          'RubyLLM::Agents::Result',
          success?: true,
          content: 'How can I help?',
          input_tokens: 50,
          output_tokens: 25,
          tool_calls: []
        )
        allow(ConversationAgent).to receive(:call).and_return(agent_result)

        message = create(:message, conversation: conversation, message_type: :incoming, content: 'New question')
        message_event = Events::Base.new('message.created', Time.zone.now, message: message)

        expect {
          perform_enqueued_jobs do
            AlooAgentListener.instance.message_created(message_event)
          end
        }.to change { conversation.messages.where(message_type: :outgoing).count }.by(1)
      end
    end
  end

  describe 'handoff to specific team' do
    let(:billing_team) { create(:team, name: 'Billing', account: account) }
    let(:billing_agent) { create(:user, account: account, role: :agent) }

    before do
      create(:team_member, team: billing_team, user: billing_agent)
      create(:inbox_member, inbox: inbox, user: billing_agent)

      Aloo::Current.account = account
      Aloo::Current.assistant = assistant
      Aloo::Current.conversation = conversation
    end

    after do
      Aloo::Current.reset
    end

    it 'assigns to team agent when team specified' do
      mcp = HandoffMcp.new

      result = mcp.execute(
        reason: 'Billing question',
        priority: 'normal',
        preferred_team: 'Billing'
      )

      expect(result[:data][:assigned_agent]).to eq(billing_agent)
    end

    it 'creates handoff note with team info' do
      mcp = HandoffMcp.new

      expect {
        mcp.execute(
          reason: 'Billing dispute',
          priority: 'high',
          summary: 'Customer disputing charge',
          preferred_team: 'Billing'
        )
      }.to change { conversation.messages.where(private: true).count }.by(1)

      note = conversation.messages.where(private: true).last
      expect(note.content).to include('Billing dispute')
      expect(note.content).to include('High')
    end
  end
end
