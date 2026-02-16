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
    let(:document) { create(:aloo_document, :available, title: 'Return Policy', assistant: assistant, account: account) }
    let(:mock_embeddings) { [] }

    before do
      allow(Aloo::Embedding).to receive(:search).and_return(mock_embeddings)
    end

    it 'searches the knowledge base with query' do
      expect(Aloo::Embedding).to receive(:search).with(
        'return policy',
        assistant: assistant,
        limit: 5,
        source_types: nil
      ).and_return([])

      tool.execute(query: 'return policy')
    end

    it 'passes source_types filter when provided' do
      expect(Aloo::Embedding).to receive(:search).with(
        'test',
        assistant: assistant,
        limit: 5,
        source_types: ['file']
      ).and_return([])

      tool.execute(query: 'test', source_types: ['file'])
    end

    context 'with results' do
      let(:embedding1) { create(:aloo_embedding, document: document, content: 'Returns within 30 days', assistant: assistant, account: account) }
      let(:faq_doc) { create(:aloo_document, :available, title: 'FAQ', assistant: assistant, account: account) }
      let(:embedding2) { create(:aloo_embedding, document: faq_doc, content: 'See our return policy', assistant: assistant, account: account) }

      before do
        allow(Aloo::Embedding).to receive(:search).and_return([embedding1, embedding2])
        allow(embedding1).to receive(:similarity).and_return(0.9)
        allow(embedding2).to receive(:similarity).and_return(0.8)
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
        allow(Aloo::Embedding).to receive(:search).and_raise(StandardError, 'Search failed')
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
