# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ConversationAgent, :aloo do
  let(:account) { create(:account) }
  let(:assistant) { create(:aloo_assistant, :with_all_features, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:contact) { conversation.contact }

  before do
    Aloo::Current.account = account
    Aloo::Current.assistant = assistant
    Aloo::Current.conversation = conversation
    Aloo::Current.contact = contact
    Aloo::Current.inbox = inbox
  end

  after do
    Aloo::Current.reset
  end

  describe 'configuration' do
    it 'has expected temperature' do
      expect(described_class.temperature).to eq(0.7)
    end

    it 'has expected timeout' do
      expect(described_class.timeout).to eq(60)
    end
  end

  describe '#model' do
    it 'uses gemini-2.5-flash for cost-effective tool calling' do
      agent = described_class.new(message: 'test')
      expect(agent.model).to eq('gemini-2.5-flash')
    end
  end

  describe '#system_prompt' do
    let(:agent) { described_class.new(message: 'test query') }

    it 'includes base instructions with knowledge_lookup guidance' do
      prompt = agent.system_prompt

      expect(prompt).to include('customer support assistant')
      expect(prompt).to include('knowledge_lookup')
    end

    it 'does not include pre-loaded knowledge context' do
      prompt = agent.system_prompt

      expect(prompt).not_to include('## Relevant Information')
    end

    it 'does not include pre-loaded memory context' do
      prompt = agent.system_prompt

      expect(prompt).not_to include('## Customer Context')
    end

    it 'includes personality prompt' do
      allow_any_instance_of(Aloo::PersonalityBuilder).to receive(:build).and_return('Personality instructions')

      new_agent = described_class.new(message: 'test query')
      prompt = new_agent.system_prompt

      expect(prompt).to include('Personality instructions')
    end

    it 'includes contact and channel info' do
      prompt = agent.system_prompt

      expect(prompt).to include('Contact:')
      expect(prompt).to include('Channel:')
    end
  end

  describe '#user_prompt' do
    it 'returns just the current message' do
      agent = described_class.new(message: 'What is your refund policy?')
      prompt = agent.user_prompt

      expect(prompt).to eq('What is your refund policy?')
    end
  end

  describe '#messages' do
    context 'without conversation history' do
      it 'returns an empty array' do
        agent = described_class.new(message: 'First message')
        expect(agent.messages).to eq([])
      end
    end

    context 'with existing conversation history' do
      let!(:incoming_message) do
        create(:message, conversation: conversation, message_type: :incoming, content: 'Hi')
      end
      let!(:outgoing_message) do
        create(:message, conversation: conversation, message_type: :outgoing, content: 'Hello!')
      end

      it 'returns structured message history with correct roles' do
        agent = described_class.new(message: 'Follow up question')
        messages = agent.messages

        expect(messages).to be_an(Array)
        expect(messages.length).to eq(2)
        expect(messages).to include({ role: :user, content: 'Hi' })
        expect(messages).to include({ role: :assistant, content: 'Hello!' })
      end
    end
  end

  describe '#tools' do
    it 'includes KnowledgeLookupTool' do
      agent = described_class.new(message: 'test')
      expect(agent.tools).to include(KnowledgeLookupTool)
    end

    it 'does not include deprecated FaqLookupTool' do
      agent = described_class.new(message: 'test')
      expect(agent.tools).not_to include(FaqLookupTool)
    end

    context 'with memory feature enabled' do
      it 'includes MemoryLookupTool' do
        agent = described_class.new(message: 'test')
        expect(agent.tools).to include(MemoryLookupTool)
      end
    end

    context 'with memory feature disabled' do
      let(:assistant) { create(:aloo_assistant, account: account, admin_config: { 'feature_memory' => false }) }

      it 'does not include MemoryLookupTool' do
        agent = described_class.new(message: 'test')
        expect(agent.tools).not_to include(MemoryLookupTool)
      end
    end

    it 'includes HandoffTool when enabled' do
      agent = described_class.new(message: 'test')
      expect(agent.tools).to include(HandoffTool)
    end
  end

  describe '.call' do
    context 'with dry_run: true' do
      it 'returns prompts without API call' do
        result = described_class.call(
          message: 'What is your refund policy?',
          dry_run: true
        )

        expect(result).to respond_to(:content)
        expect(result).to respond_to(:success?)
      end

      it 'includes system_prompt in content' do
        result = described_class.call(
          message: 'Test question',
          dry_run: true
        )

        expect(result.content[:system_prompt]).to include('customer support assistant')
      end

      it 'includes user_prompt in content' do
        result = described_class.call(
          message: 'What is your policy?',
          dry_run: true
        )

        expect(result.content[:user_prompt]).to include('What is your policy?')
      end
    end
  end
end
