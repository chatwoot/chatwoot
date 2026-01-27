# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aloo::FaqGeneratorJob, type: :job do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let(:assistant) { create(:aloo_assistant, :with_faq_enabled, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :resolved) }

  before do
    create(:aloo_assistant_inbox, assistant: assistant, inbox: inbox)
    # Need at least 4 messages for FAQ generation
    create_list(:message, 3, conversation: conversation, message_type: :incoming, content: 'Customer question')
    create_list(:message, 2, conversation: conversation, message_type: :outgoing, content: 'Agent answer')
  end

  describe '#perform' do
    context 'when preconditions not met' do
      it 'returns early when conversation not found' do
        expect(FaqGeneratorAgent).not_to receive(:call)
        described_class.new.perform(999_999)
      end

      it 'returns early when assistant inactive' do
        assistant.update!(active: false)
        expect(FaqGeneratorAgent).not_to receive(:call)
        described_class.new.perform(conversation.id)
      end

      it 'returns early when FAQ feature disabled' do
        assistant.update!(admin_config: {})
        expect(FaqGeneratorAgent).not_to receive(:call)
        described_class.new.perform(conversation.id)
      end

      it 'returns early when not resolved' do
        conversation.update!(status: :open)
        expect(FaqGeneratorAgent).not_to receive(:call)
        described_class.new.perform(conversation.id)
      end

      it 'returns early when already processed' do
        create(:aloo_conversation_context,
               conversation: conversation,
               assistant: assistant,
               context_data: { 'faq_generation_completed' => true })

        expect(FaqGeneratorAgent).not_to receive(:call)
        described_class.new.perform(conversation.id)
      end

      it 'returns early when insufficient messages' do
        conversation.messages.destroy_all
        create(:message, conversation: conversation, message_type: :incoming)

        expect(FaqGeneratorAgent).not_to receive(:call)
        described_class.new.perform(conversation.id)
      end
    end

    context 'when generation succeeds' do
      let(:agent_result) do
        instance_double(
          'RubyLLM::Agents::Result',
          success?: true,
          content: {
            faqs: [
              { 'question' => 'How do I reset my password?', 'answer' => 'Click forgot password', 'topics' => ['account'], 'confidence' => 0.9 },
              { 'question' => 'What is the return policy?', 'answer' => '30 days', 'topics' => ['returns'], 'confidence' => 0.8 }
            ]
          }
        )
      end

      before do
        allow(FaqGeneratorAgent).to receive(:call).and_return(agent_result)
        allow(Aloo::Embedding).to receive(:embed_text)
          .and_return(Array.new(1536) { 0.0 })
        allow_any_instance_of(Aloo::MemorySearchService).to receive(:find_duplicate).and_return(nil)
      end

      it 'calls FaqGeneratorAgent' do
        expect(FaqGeneratorAgent).to receive(:call).with(
          transcript: anything,
          max_faqs: 3
        )

        described_class.new.perform(conversation.id)
      end

      it 'creates FAQ memory records' do
        expect do
          described_class.new.perform(conversation.id)
        end.to change { Aloo::Memory.where(memory_type: 'faq').count }.by(2)
      end

      it 'marks conversation as processed' do
        described_class.new.perform(conversation.id)

        context = Aloo::ConversationContext.find_by(conversation: conversation)
        expect(context.context_data['faq_generation_completed']).to be true
      end

      it 'stores FAQs with correct format' do
        described_class.new.perform(conversation.id)

        faq = Aloo::Memory.find_by(memory_type: 'faq')
        expect(faq.content).to include('Q:')
        expect(faq.content).to include('A:')
      end

      it 'stores FAQs as global (no contact)' do
        described_class.new.perform(conversation.id)

        faqs = Aloo::Memory.where(memory_type: 'faq')
        faqs.each do |faq|
          expect(faq.contact).to be_nil
        end
      end
    end

    context 'when duplicate FAQ exists' do
      let(:agent_result) do
        instance_double(
          'RubyLLM::Agents::Result',
          success?: true,
          content: { faqs: [{ 'question' => 'Existing Q?', 'answer' => 'Existing A', 'confidence' => 0.8 }] }
        )
      end
      let(:existing_faq) { create(:aloo_memory, :faq, content: 'Q: Existing Q?\nA: Existing A', assistant: assistant, account: account) }

      before do
        allow(FaqGeneratorAgent).to receive(:call).and_return(agent_result)
        allow_any_instance_of(Aloo::MemorySearchService).to receive(:find_duplicate).and_return(existing_faq)
      end

      it 'updates existing FAQ observation count' do
        expect do
          described_class.new.perform(conversation.id)
        end.to change { existing_faq.reload.observation_count }.by(1)
      end
    end
  end

  describe 'job configuration' do
    it 'is queued in low queue' do
      expect(described_class.new.queue_name).to eq('low')
    end
  end
end
