# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Aloo FAQ Generation Flow', type: :integration do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let(:assistant) { create(:aloo_assistant, :with_faq_enabled, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :resolved) }

  let(:agent_result) do
    instance_double(
      'RubyLLM::Agents::Result',
      success?: true,
      content: {
        faqs: [
          { 'question' => 'How do I reset my password?', 'answer' => 'Click the forgot password link on the login page.', 'topics' => ['account', 'password'], 'confidence' => 0.9 },
          { 'question' => 'What is your return policy?', 'answer' => 'We offer 30-day returns for all products.', 'topics' => ['returns', 'policy'], 'confidence' => 0.85 }
        ]
      }
    )
  end

  before do
    create(:aloo_assistant_inbox, assistant: assistant, inbox: inbox)
    create_list(:message, 5, conversation: conversation, message_type: :incoming, content: 'Customer question')
    create_list(:message, 4, conversation: conversation, message_type: :outgoing, content: 'Agent answer')

    allow(RubyLLM).to receive(:embed).and_return(
      instance_double('RubyLLM::Embedding', vectors: Array.new(1536) { rand(-1.0..1.0) })
    )
    allow(FaqGeneratorAgent).to receive(:call).and_return(agent_result)
    allow_any_instance_of(Aloo::MemorySearchService).to receive(:find_duplicate).and_return(nil)
  end

  describe 'FAQ creation' do
    let(:event) { Events::Base.new('conversation.resolved', Time.zone.now, conversation: conversation) }

    it 'generates FAQs after resolution' do
      expect {
        perform_enqueued_jobs do
          AlooAgentListener.instance.conversation_resolved(event)
        end
      }.to change { Aloo::Memory.where(memory_type: 'faq').count }.by(2)
    end

    it 'stores FAQ with embedding' do
      perform_enqueued_jobs do
        AlooAgentListener.instance.conversation_resolved(event)
      end

      faq = Aloo::Memory.find_by(memory_type: 'faq')
      expect(faq.embedding).to be_present
      expect(faq.embedding.size).to eq(1536)
    end

    it 'formats FAQ content correctly' do
      perform_enqueued_jobs do
        AlooAgentListener.instance.conversation_resolved(event)
      end

      faq = Aloo::Memory.find_by(content: /reset my password/)
      expect(faq.content).to include('Q:')
      expect(faq.content).to include('A:')
      expect(faq.content).to include('forgot password link')
    end

    it 'stores topics from generation' do
      perform_enqueued_jobs do
        AlooAgentListener.instance.conversation_resolved(event)
      end

      faq = Aloo::Memory.find_by(content: /reset my password/)
      expect(faq.topics).to include('account')
      expect(faq.topics).to include('password')
    end

    it 'stores confidence from generation' do
      perform_enqueued_jobs do
        AlooAgentListener.instance.conversation_resolved(event)
      end

      faq = Aloo::Memory.find_by(content: /reset my password/)
      expect(faq.confidence).to eq(0.9)
    end

    it 'stores FAQs as global (no contact)' do
      perform_enqueued_jobs do
        AlooAgentListener.instance.conversation_resolved(event)
      end

      Aloo::Memory.where(memory_type: 'faq').each do |faq|
        expect(faq.contact).to be_nil
      end
    end

    it 'marks conversation as processed' do
      perform_enqueued_jobs do
        AlooAgentListener.instance.conversation_resolved(event)
      end

      context = Aloo::ConversationContext.find_by(conversation: conversation)
      expect(context.context_data['faq_generation_completed']).to be true
    end

    context 'with insufficient messages' do
      before do
        conversation.messages.destroy_all
        create(:message, conversation: conversation, message_type: :incoming)
      end

      it 'skips FAQ generation' do
        expect {
          perform_enqueued_jobs do
            AlooAgentListener.instance.conversation_resolved(event)
          end
        }.not_to change { Aloo::Memory.where(memory_type: 'faq').count }
      end

      it 'marks as processed with skipped flag' do
        perform_enqueued_jobs do
          AlooAgentListener.instance.conversation_resolved(event)
        end

        context = Aloo::ConversationContext.find_by(conversation: conversation)
        result = context.context_data['faq_generation_result']
        expect(result['skipped']).to be true
      end
    end
  end
end
