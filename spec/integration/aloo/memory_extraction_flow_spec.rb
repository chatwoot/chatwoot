# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Aloo Memory Extraction Flow', type: :integration do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let(:assistant) { create(:aloo_assistant, :with_memory_enabled, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :resolved) }
  let(:contact) { conversation.contact }

  let(:agent_result) do
    instance_double(
      'RubyLLM::Agents::Result',
      success?: true,
      content: {
        memories: [
          { 'type' => 'preference', 'content' => 'Customer prefers email communication', 'contact_specific' => true, 'entities' => [], 'topics' => ['communication'] },
          { 'type' => 'procedure', 'content' => 'Escalate billing issues to finance team', 'contact_specific' => false, 'entities' => ['billing'], 'topics' => ['escalation'] }
        ]
      }
    )
  end

  before do
    create(:aloo_assistant_inbox, assistant: assistant, inbox: inbox)
    create_list(:message, 5, conversation: conversation, message_type: :incoming, content: 'Customer message')
    create_list(:message, 4, conversation: conversation, message_type: :outgoing, content: 'Agent response')

    allow(RubyLLM).to receive(:embed).and_return(
      instance_double('RubyLLM::Embedding', vectors: Array.new(1536) { rand(-1.0..1.0) })
    )
    allow(MemoryExtractorAgent).to receive(:call).and_return(agent_result)
    allow_any_instance_of(Aloo::MemorySearchService).to receive(:find_duplicate).and_return(nil)
  end

  describe 'conversation resolution' do
    let(:event) { Events::Base.new('conversation.resolved', Time.zone.now, conversation: conversation) }

    it 'extracts memories after resolution' do
      expect {
        perform_enqueued_jobs do
          AlooAgentListener.instance.conversation_resolved(event)
        end
      }.to change(Aloo::Memory, :count).by(2)
    end

    it 'creates contact-scoped memories with contact' do
      perform_enqueued_jobs do
        AlooAgentListener.instance.conversation_resolved(event)
      end

      preference = Aloo::Memory.find_by(memory_type: 'preference')
      expect(preference.contact).to eq(contact)
      expect(preference.content).to include('email communication')
    end

    it 'creates global memories without contact' do
      perform_enqueued_jobs do
        AlooAgentListener.instance.conversation_resolved(event)
      end

      procedure = Aloo::Memory.find_by(memory_type: 'procedure')
      expect(procedure.contact).to be_nil
      expect(procedure.content).to include('billing issues')
    end

    it 'stores embeddings for memories' do
      perform_enqueued_jobs do
        AlooAgentListener.instance.conversation_resolved(event)
      end

      Aloo::Memory.all.each do |memory|
        expect(memory.embedding).to be_present
        expect(memory.embedding.size).to eq(1536)
      end
    end

    it 'marks conversation as processed' do
      perform_enqueued_jobs do
        AlooAgentListener.instance.conversation_resolved(event)
      end

      context = Aloo::ConversationContext.find_by(conversation: conversation)
      expect(context.context_data['memory_extraction_completed']).to be true
    end

    it 'stores metadata about extraction' do
      perform_enqueued_jobs do
        AlooAgentListener.instance.conversation_resolved(event)
      end

      context = Aloo::ConversationContext.find_by(conversation: conversation)
      result = context.context_data['memory_extraction_result']
      expect(result['memories_extracted']).to eq(2)
      expect(result['processed_at']).to be_present
    end

    context 'with duplicate memories' do
      let(:existing_memory) do
        create(:aloo_memory, :preference,
               content: 'Customer prefers email',
               contact: contact,
               assistant: assistant,
               account: account,
               observation_count: 1)
      end

      before do
        allow_any_instance_of(Aloo::MemorySearchService)
          .to receive(:find_duplicate)
          .and_return(existing_memory, nil)
      end

      it 'updates existing memory observation count' do
        expect {
          perform_enqueued_jobs do
            AlooAgentListener.instance.conversation_resolved(event)
          end
        }.to change { existing_memory.reload.observation_count }.from(1).to(2)
      end
    end
  end
end
