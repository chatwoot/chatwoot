# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FaqLookupTool, :aloo do
  let(:account) { create(:account) }
  let(:assistant) { create(:aloo_assistant, account: account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:contact) { conversation.contact }

  before do
    Aloo::Current.account = account
    Aloo::Current.assistant = assistant
    Aloo::Current.conversation = conversation
    Aloo::Current.contact = contact
  end

  after do
    Aloo::Current.reset
  end

  describe '.description' do
    it 'indicates the tool is deprecated' do
      expect(described_class.description).to include('DEPRECATED')
    end

    it 'describes the tool purpose' do
      expect(described_class.description).to include('knowledge base')
      expect(described_class.description).to include('memories')
    end
  end

  describe '#execute' do
    let(:tool) { described_class.new }
    let(:vector_service) { instance_double(Aloo::VectorSearchService) }
    let(:memory_service) { instance_double(Aloo::MemorySearchService) }

    before do
      allow(Aloo::VectorSearchService).to receive(:new).and_return(vector_service)
      allow(Aloo::MemorySearchService).to receive(:new).and_return(memory_service)
      allow(vector_service).to receive(:search).and_return([])
      allow(memory_service).to receive(:search).and_return([])
    end

    it 'logs deprecation warning' do
      expect(Rails.logger).to receive(:warn).with(/DEPRECATED.*FaqLookupTool/)

      tool.execute(query: 'test')
    end

    context 'when search_type is "both"' do
      it 'searches knowledge base' do
        expect(vector_service).to receive(:search).with('return policy', limit: 5, source_types: nil)

        tool.execute(query: 'return policy', search_type: 'both')
      end

      it 'searches memories' do
        expect(memory_service).to receive(:search)
          .with('return policy', contact: contact, limit: 5)

        tool.execute(query: 'return policy', search_type: 'both')
      end

      it 'formats combined results' do
        allow(vector_service).to receive(:search).and_return([
                                                               { document_title: 'Policy', content: 'Return in 30 days' }
                                                             ])
        allow(memory_service).to receive(:search).and_return([
                                                               { memory_type: 'preference', content: 'Prefers email', is_contact_scoped: true }
                                                             ])

        result = tool.execute(query: 'test', search_type: 'both')

        expect(result[:success]).to be true
        expect(result[:message]).to include('Knowledge Base Results')
        expect(result[:message]).to include('Relevant Memories')
      end
    end

    context 'when search_type is "knowledge"' do
      it 'only searches knowledge base' do
        expect(vector_service).to receive(:search)
        expect(memory_service).not_to receive(:search)

        tool.execute(query: 'policy', search_type: 'knowledge')
      end
    end

    context 'when search_type is "memory"' do
      it 'only searches memories' do
        expect(vector_service).not_to receive(:search)
        expect(memory_service).to receive(:search)

        tool.execute(query: 'customer info', search_type: 'memory')
      end
    end

    context 'when include_customer_context is false' do
      it 'searches memories without contact' do
        expect(memory_service).to receive(:search)
          .with('query', contact: nil, limit: 5)

        tool.execute(query: 'query', search_type: 'memory', include_customer_context: false)
      end
    end

    context 'when no results found' do
      it 'returns appropriate message' do
        result = tool.execute(query: 'nonexistent topic')

        expect(result[:success]).to be true
        expect(result[:message]).to include('No relevant information found')
      end
    end

    context 'when underlying tool returns error' do
      before do
        allow(vector_service).to receive(:search).and_raise(StandardError, 'Search failed')
      end

      it 'handles errors gracefully by returning empty results for that tool' do
        # Errors in underlying tools are caught and return empty results
        # This ensures backward compatibility and graceful degradation
        result = tool.execute(query: 'test')

        expect(result[:success]).to be true
        expect(result[:knowledge_results]).to be_nil.or eq([])
      end
    end

    context 'when FaqLookupTool itself fails' do
      before do
        allow(KnowledgeLookupTool).to receive(:new).and_raise(StandardError, 'Tool creation failed')
      end

      it 'logs execution with error' do
        expect_any_instance_of(described_class).to receive(:log_execution)
          .with(anything, anything, success: false, error_message: 'Tool creation failed')

        tool.execute(query: 'test')
      end

      it 'returns error response' do
        result = tool.execute(query: 'test')

        expect(result[:success]).to be false
        expect(result[:error]).to include('Search failed')
      end
    end

    context 'without required context' do
      before do
        Aloo::Current.account = nil
      end

      it 'raises error' do
        expect { tool.execute(query: 'test') }.to raise_error('Account context required')
      end
    end
  end
end
