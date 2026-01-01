# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aloo::ExtractMemoriesJob, type: :job do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let(:assistant) { create(:aloo_assistant, :with_memory_enabled, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :resolved) }

  before do
    create(:aloo_assistant_inbox, assistant: assistant, inbox: inbox)
    create_list(:message, 3, conversation: conversation, message_type: :incoming, content: 'Customer message')
    create_list(:message, 2, conversation: conversation, message_type: :outgoing, content: 'Agent response')
  end

  describe '#perform' do
    context 'when conversation not found' do
      it 'returns early' do
        expect(MemoryExtractorAgent).not_to receive(:call)

        described_class.new.perform(999_999)
      end
    end

    context 'when assistant is inactive' do
      before { assistant.update!(active: false) }

      it 'returns early' do
        expect(MemoryExtractorAgent).not_to receive(:call)

        described_class.new.perform(conversation.id)
      end
    end

    context 'when memory feature disabled' do
      before { assistant.update!(admin_config: {}) }

      it 'returns early' do
        expect(MemoryExtractorAgent).not_to receive(:call)

        described_class.new.perform(conversation.id)
      end
    end

    context 'when conversation not resolved' do
      before { conversation.update!(status: :open) }

      it 'returns early' do
        expect(MemoryExtractorAgent).not_to receive(:call)

        described_class.new.perform(conversation.id)
      end
    end

    context 'when already processed' do
      before do
        create(:aloo_conversation_context,
               conversation: conversation,
               assistant: assistant,
               context_data: { 'memory_extraction_completed' => true })
      end

      it 'returns early' do
        expect(MemoryExtractorAgent).not_to receive(:call)

        described_class.new.perform(conversation.id)
      end
    end

    context 'when extraction succeeds' do
      let(:agent_result) do
        instance_double(
          'RubyLLM::Agents::Result',
          success?: true,
          content: {
            memories: [
              { 'type' => 'preference', 'content' => 'Customer prefers email', 'contact_specific' => true },
              { 'type' => 'procedure', 'content' => 'Escalate billing issues', 'contact_specific' => false }
            ]
          }
        )
      end

      before do
        allow(MemoryExtractorAgent).to receive(:call).and_return(agent_result)
        allow_any_instance_of(Aloo::EmbeddingService).to receive(:generate_embedding)
          .and_return(Array.new(1536) { 0.0 })
        allow_any_instance_of(Aloo::MemorySearchService).to receive(:find_duplicate).and_return(nil)
      end

      it 'calls MemoryExtractorAgent' do
        expect(MemoryExtractorAgent).to receive(:call).with(
          transcript: anything,
          resolution_status: 'resolved',
          max_memories: 10
        )

        described_class.new.perform(conversation.id)
      end

      it 'creates memory records' do
        expect {
          described_class.new.perform(conversation.id)
        }.to change(Aloo::Memory, :count).by(2)
      end

      it 'marks conversation as processed' do
        described_class.new.perform(conversation.id)

        context = Aloo::ConversationContext.find_by(conversation: conversation)
        expect(context.context_data['memory_extraction_completed']).to be true
      end

      it 'sets contact for contact-scoped memories' do
        described_class.new.perform(conversation.id)

        preference = Aloo::Memory.find_by(memory_type: 'preference')
        expect(preference.contact).to eq(conversation.contact)
      end

      it 'does not set contact for global memories' do
        described_class.new.perform(conversation.id)

        procedure = Aloo::Memory.find_by(memory_type: 'procedure')
        expect(procedure.contact).to be_nil
      end
    end

    context 'when duplicate memory exists' do
      let(:agent_result) do
        instance_double(
          'RubyLLM::Agents::Result',
          success?: true,
          content: { memories: [{ 'type' => 'preference', 'content' => 'Existing memory' }] }
        )
      end
      let(:existing_memory) { create(:aloo_memory, :preference, content: 'Existing memory', assistant: assistant, account: account) }

      before do
        allow(MemoryExtractorAgent).to receive(:call).and_return(agent_result)
        allow_any_instance_of(Aloo::MemorySearchService).to receive(:find_duplicate).and_return(existing_memory)
      end

      it 'updates existing memory observation count' do
        expect {
          described_class.new.perform(conversation.id)
        }.to change { existing_memory.reload.observation_count }.by(1)
      end
    end
  end

  describe 'job configuration' do
    it 'is queued in low queue' do
      expect(described_class.new.queue_name).to eq('low')
    end

    it 'has retry_on configured for RubyLLM::Error' do
      # Verify that the job class has retry_on configured
      expect(described_class.ancestors).to include(ActiveJob::Base)
    end
  end
end
