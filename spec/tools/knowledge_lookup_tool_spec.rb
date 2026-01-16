# frozen_string_literal: true

require 'rails_helper'

RSpec.describe KnowledgeLookupTool, :aloo do
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
    it 'describes the tool purpose' do
      expect(described_class.description).to include('knowledge base')
      expect(described_class.description).to include('products')
      expect(described_class.description).to include('policies')
    end
  end

  describe '#execute' do
    let(:tool) { described_class.new }
    let(:vector_service) { instance_double(Aloo::VectorSearchService) }

    before do
      allow(Aloo::VectorSearchService).to receive(:new).and_return(vector_service)
      allow(vector_service).to receive(:search).and_return([])
    end

    it 'searches the knowledge base with query' do
      expect(vector_service).to receive(:search).with('return policy', limit: 5, source_types: nil)

      tool.execute(query: 'return policy')
    end

    it 'passes source_types filter when provided' do
      expect(vector_service).to receive(:search).with('test', limit: 5, source_types: ['file'])

      tool.execute(query: 'test', source_types: ['file'])
    end

    context 'with results' do
      before do
        allow(vector_service).to receive(:search).and_return([
                                                               { document_title: 'Return Policy', content: 'Returns within 30 days' },
                                                               { document_title: 'FAQ', content: 'See our return policy' }
                                                             ])
      end

      it 'formats results correctly' do
        result = tool.execute(query: 'returns')

        expect(result[:success]).to be true
        expect(result[:message]).to include('Knowledge Base Results')
        expect(result[:message]).to include('Return Policy')
        expect(result[:results].size).to eq(2)
      end
    end

    context 'with no results' do
      it 'returns appropriate message' do
        result = tool.execute(query: 'nonexistent')

        expect(result[:success]).to be true
        expect(result[:message]).to include('No relevant information found')
        expect(result[:results]).to be_empty
      end
    end

    context 'when error occurs' do
      before do
        allow(vector_service).to receive(:search).and_raise(StandardError, 'Search failed')
      end

      it 'returns error response' do
        result = tool.execute(query: 'test')

        expect(result[:success]).to be false
        expect(result[:error]).to include('Knowledge search failed')
      end
    end

    context 'without required context' do
      before do
        Aloo::Current.account = nil
      end

      it 'returns error response' do
        result = tool.execute(query: 'test')

        expect(result[:success]).to be false
        expect(result[:error]).to include('Account context required')
      end
    end
  end
end
