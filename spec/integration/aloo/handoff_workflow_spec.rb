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
    let(:handoff_tool_call) { { 'name' => 'handoff' } }
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

      expect do
        perform_enqueued_jobs do
          AlooAgentListener.instance.message_created(event)
        end
      end.not_to(change { conversation.messages.where(sender_type: 'Aloo::Assistant').count })
    end

    # NOTE: The status update to 'open' is handled by HandoffTool during actual execution.
    # Since ConversationAgent.call is mocked here, the tool doesn't run.
    # The status change is tested in spec/tools/handoff_tool_spec.rb
  end

  describe 'human assignee as handoff gate' do
    context 'when human agent is assigned' do
      before do
        conversation.update!(assignee: agent)
      end

      it 'blocks AI responses when human assigned' do
        allow(ConversationAgent).to receive(:call)

        message = create(:message, conversation: conversation, message_type: :incoming, content: 'Hello')
        event = Events::Base.new('message.created', Time.zone.now, message: message)

        expect(Aloo::ResponseJob).not_to receive(:perform_later)

        AlooAgentListener.instance.message_created(event)
      end

      it 'clears assignee when conversation reopened from resolved' do
        event = Events::Base.new(
          'conversation.status_changed',
          Time.zone.now,
          conversation: conversation,
          changed_attributes: { 'status' => %w[resolved open] }
        )

        AlooAgentListener.instance.conversation_status_changed(event)

        expect(conversation.reload.assignee).to be_nil
      end

      it 'allows AI responses after assignee cleared on reopen' do
        # First, reopen to clear assignee
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

        expect do
          perform_enqueued_jobs do
            AlooAgentListener.instance.message_created(message_event)
          end
        end.to change { conversation.messages.where(message_type: :outgoing).count }.by(1)
      end
    end
  end

  describe 'AI cannot trigger true handoff' do
    before do
      Aloo::Current.account = account
      Aloo::Current.assistant = assistant
      Aloo::Current.conversation = conversation
    end

    after do
      Aloo::Current.reset
    end

    it 'AI tool only requests assistance, does not assign a human' do
      tool = HandoffTool.new

      tool.execute(
        reason: 'Customer needs help',
        priority: 'normal'
      )

      # AI can only request assistance - cannot assign humans
      expect(conversation.reload.custom_attributes['human_assistance_requested']).to be true
      expect(conversation.reload.assignee).to be_nil
    end

    it 'AI tool does not assign conversation to any agent' do
      tool = HandoffTool.new

      tool.execute(
        reason: 'Billing question',
        priority: 'normal',
        preferred_team: 'Billing'
      )

      # AI cannot assign agents
      expect(conversation.reload.assignee).to be_nil
    end

    it 'creates assistance request note' do
      tool = HandoffTool.new

      expect do
        tool.execute(
          reason: 'Billing dispute',
          priority: 'high',
          summary: 'Customer disputing charge'
        )
      end.to change { conversation.messages.where(private: true).count }.by(1)

      note = conversation.messages.where(private: true).last
      expect(note.content).to include('Billing dispute')
      expect(note.content).to include('High')
    end
  end

  describe 'only human self-assignment stops AI' do
    it 'AI stops responding when human agent assigns themselves' do
      conversation.update!(assignee: agent)

      message = create(:message, conversation: conversation, message_type: :incoming, content: 'Hello')
      event = Events::Base.new('message.created', Time.zone.now, message: message)

      expect(Aloo::ResponseJob).not_to receive(:perform_later)

      AlooAgentListener.instance.message_created(event)
    end
  end
end
