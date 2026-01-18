# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Aloo Message Response Pipeline', type: :integration do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let(:assistant) { create(:aloo_assistant, :with_all_features, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :pending) }
  let(:contact) { conversation.contact }

  let(:agent_result) do
    instance_double(
      'RubyLLM::Agents::Result',
      success?: true,
      content: 'Hello! Based on our FAQ, here is your answer.',
      input_tokens: 150,
      output_tokens: 75,
      tool_calls: []
    )
  end

  before do
    create(:aloo_assistant_inbox, assistant: assistant, inbox: inbox)

    # Setup knowledge base
    document = create(:aloo_document, :available, assistant: assistant, account: account)
    create(:aloo_embedding, document: document, assistant: assistant, account: account)

    # Mock RubyLLM
    allow(RubyLLM).to receive(:embed).and_return(
      instance_double('RubyLLM::Embedding', vectors: Array.new(1536) { 0.0 })
    )
    allow(ConversationAgent).to receive(:call).and_return(agent_result)
  end

  describe 'incoming message handling' do
    let(:message) { create(:message, conversation: conversation, message_type: :incoming, content: 'What is your return policy?') }
    let(:event) { Events::Base.new('message.created', Time.zone.now, message: message) }

    it 'processes message and generates response' do
      perform_enqueued_jobs do
        AlooAgentListener.instance.message_created(event)
      end

      expect(conversation.messages.where(message_type: :outgoing).count).to eq(1)
      response = conversation.messages.where(message_type: :outgoing).last
      expect(response.content).to eq('Hello! Based on our FAQ, here is your answer.')
    end

    it 'updates conversation status' do
      perform_enqueued_jobs do
        AlooAgentListener.instance.message_created(event)
      end

      expect(conversation.reload.status).to eq('open')
    end

    it 'tracks usage in ConversationContext' do
      perform_enqueued_jobs do
        AlooAgentListener.instance.message_created(event)
      end

      context = Aloo::ConversationContext.find_by(conversation: conversation)
      expect(context).to be_present
      expect(context.message_count).to eq(1)
      expect(context.input_tokens).to eq(150)
      expect(context.output_tokens).to eq(75)
    end

    it 'stores aloo_generated attribute in message' do
      perform_enqueued_jobs do
        AlooAgentListener.instance.message_created(event)
      end

      response = conversation.messages.where(message_type: :outgoing).last
      expect(response.content_attributes['aloo_generated']).to be true
      expect(response.content_attributes['aloo_assistant_id']).to eq(assistant.id)
    end

    context 'with multiple messages' do
      it 'includes conversation history' do
        create(:message, conversation: conversation, message_type: :incoming, content: 'First question')
        create(:message, conversation: conversation, message_type: :outgoing, content: 'First answer')

        expect(ConversationAgent).to receive(:call) do |args|
          expect(args[:conversation_history]).to include('First question')
          expect(args[:conversation_history]).to include('First answer')
          agent_result
        end

        perform_enqueued_jobs do
          AlooAgentListener.instance.message_created(event)
        end
      end
    end
  end

  describe 'message not processed when' do
    it 'handoff is active' do
      conversation.update!(custom_attributes: { 'aloo_handoff_active' => true })
      message = create(:message, conversation: conversation, message_type: :incoming, content: 'Hello')
      event = Events::Base.new('message.created', Time.zone.now, message: message)

      expect {
        perform_enqueued_jobs do
          AlooAgentListener.instance.message_created(event)
        end
      }.not_to change { conversation.messages.where(message_type: :outgoing).count }
    end

    it 'human agent is assigned' do
      agent = create(:user, account: account)
      conversation.update!(assignee: agent)
      message = create(:message, conversation: conversation, message_type: :incoming, content: 'Hello')
      event = Events::Base.new('message.created', Time.zone.now, message: message)

      expect {
        perform_enqueued_jobs do
          AlooAgentListener.instance.message_created(event)
        end
      }.not_to change { conversation.messages.where(message_type: :outgoing).count }
    end
  end
end
