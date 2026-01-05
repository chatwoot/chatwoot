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

    # Stub service calls that happen in system_prompt
    allow_any_instance_of(Aloo::VectorSearchService).to receive(:search_for_context).and_return('')
    allow_any_instance_of(Aloo::MemorySearchService).to receive(:search_for_context).and_return('')
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
    it 'uses gemini-2.0-flash for cost-effective tool calling' do
      agent = described_class.new(message: 'test')
      expect(agent.model).to eq('gemini-2.0-flash')
    end
  end

  describe '#system_prompt' do
    let(:agent) { described_class.new(message: 'test query') }

    before do
      allow_any_instance_of(Aloo::VectorSearchService).to receive(:search_for_context).and_return('')
      allow_any_instance_of(Aloo::MemorySearchService).to receive(:search_for_context).and_return('')
    end

    it 'includes base instructions' do
      prompt = agent.system_prompt

      expect(prompt).to include('helpful customer support assistant')
      expect(prompt).to include('faq_lookup')
      expect(prompt).to include('handoff')
    end

    it 'includes personality prompt' do
      allow_any_instance_of(Aloo::PersonalityBuilder).to receive(:build).and_return('Personality instructions')

      new_agent = described_class.new(message: 'test query')
      prompt = new_agent.system_prompt

      expect(prompt).to include('Personality instructions')
    end

    context 'with knowledge context available' do
      before do
        allow_any_instance_of(Aloo::VectorSearchService)
          .to receive(:search_for_context)
          .and_return('Some knowledge content')
      end

      it 'includes knowledge context when available' do
        prompt = agent.system_prompt

        expect(prompt).to include('## Relevant Information')
        expect(prompt).to include('Some knowledge content')
      end
    end

    context 'with memory feature enabled' do
      before do
        allow_any_instance_of(Aloo::MemorySearchService)
          .to receive(:search_for_context)
          .and_return('Customer prefers email')
      end

      it 'includes memory context' do
        prompt = agent.system_prompt

        expect(prompt).to include('## Customer Context')
        expect(prompt).to include('Customer prefers email')
      end
    end

    it 'includes conversation context info' do
      prompt = agent.system_prompt

      expect(prompt).to include('## Conversation Context')
    end

    context 'with previous handoff history' do
      before do
        conversation.update!(custom_attributes: { 'aloo_handoff_cleared_at' => Time.current.iso8601 })
      end

      it 'includes handoff history context when conversation was previously handed off' do
        prompt = agent.system_prompt

        expect(prompt).to include('## Previous Handoff Notice')
        expect(prompt).to include('previously handed off to a human agent')
        expect(prompt).to include('CRITICAL')
        expect(prompt).to include('CURRENT message')
      end
    end

    context 'without previous handoff history' do
      it 'does not include handoff history context' do
        prompt = agent.system_prompt

        expect(prompt).not_to include('## Previous Handoff Notice')
      end
    end

    context 'when handoff feature is disabled' do
      let(:assistant) { create(:aloo_assistant, account: account, admin_config: { 'feature_handoff' => false }) }

      before do
        conversation.update!(custom_attributes: { 'aloo_handoff_cleared_at' => Time.current.iso8601 })
      end

      it 'does not include handoff history context' do
        prompt = agent.system_prompt

        expect(prompt).not_to include('## Previous Handoff Notice')
      end
    end
  end

  describe '#user_prompt' do
    it 'includes current message' do
      agent = described_class.new(message: 'What is your refund policy?')
      prompt = agent.user_prompt

      expect(prompt).to include('Current Message')
      expect(prompt).to include('What is your refund policy?')
    end

    it 'includes conversation history when provided' do
      agent = described_class.new(
        message: 'Follow up question',
        conversation_history: "Customer: Hi\nAssistant: Hello!"
      )
      prompt = agent.user_prompt

      expect(prompt).to include('Customer: Hi')
      expect(prompt).to include('Follow up question')
    end
  end

  describe '#tools' do
    it 'includes FaqLookupTool' do
      agent = described_class.new(message: 'test')
      expect(agent.tools).to include(FaqLookupTool)
    end

    it 'includes HandoffTool' do
      agent = described_class.new(message: 'test')
      expect(agent.tools).to include(HandoffTool)
    end
  end

  describe '.call' do
    context 'with dry_run: true' do
      before do
        allow_any_instance_of(Aloo::VectorSearchService).to receive(:search_for_context).and_return('')
        allow_any_instance_of(Aloo::MemorySearchService).to receive(:search_for_context).and_return('')
      end

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
