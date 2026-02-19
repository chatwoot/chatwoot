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
        limit: 5
      ).and_return([])

      tool.execute(query: 'return policy')
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

    context 'with translated_query for cross-lingual search' do
      let(:embedding1) { create(:aloo_embedding, document: document, content: 'Returns within 30 days', assistant: assistant, account: account) }
      let(:faq_doc) { create(:aloo_document, :available, title: 'FAQ', assistant: assistant, account: account) }
      let(:embedding2) { create(:aloo_embedding, document: faq_doc, content: 'Full refund policy', assistant: assistant, account: account) }
      let(:embedding3) { create(:aloo_embedding, document: document, content: 'Exchange within 14 days', assistant: assistant, account: account) }

      it 'searches with both Arabic query and English translation' do
        expect(Aloo::Embedding).to receive(:search).with(
          'سياسة الإرجاع',
          assistant: assistant, limit: 5
        ).and_return([])

        expect(Aloo::Embedding).to receive(:search).with(
          'return policy',
          assistant: assistant, limit: 5
        ).and_return([])

        tool.execute(query: 'سياسة الإرجاع', translated_query: 'return policy')
      end

      it 'searches with both English query and Arabic translation' do
        expect(Aloo::Embedding).to receive(:search).with(
          'return policy',
          assistant: assistant, limit: 5
        ).and_return([])

        expect(Aloo::Embedding).to receive(:search).with(
          'سياسة الإرجاع',
          assistant: assistant, limit: 5
        ).and_return([])

        tool.execute(query: 'return policy', translated_query: 'سياسة الإرجاع')
      end

      it 'deduplicates results keeping higher similarity' do
        low_sim = embedding1
        high_sim = embedding1.dup
        allow(low_sim).to receive(:similarity).and_return(0.5)
        allow(low_sim).to receive(:id).and_return(embedding1.id)
        allow(high_sim).to receive(:similarity).and_return(0.8)
        allow(high_sim).to receive(:id).and_return(embedding1.id)
        allow(embedding2).to receive(:similarity).and_return(0.6)

        allow(Aloo::Embedding).to receive(:search).and_return([low_sim], [high_sim, embedding2])

        result = tool.execute(query: 'ما هي سياسة الإرجاع؟', translated_query: 'what is the return policy?')

        expect(result[:results].size).to eq(2)
        expect(result[:results].first[:similarity]).to eq(0.8)
      end

      it 'returns merged results sorted by similarity desc, capped at 5' do
        embeddings = (1..4).map do |i|
          emb = create(:aloo_embedding, document: document, content: "Content #{i}", assistant: assistant, account: account)
          allow(emb).to receive(:similarity).and_return(0.9 - (i * 0.1))
          emb
        end

        extra_embeddings = (5..7).map do |i|
          emb = create(:aloo_embedding, document: document, content: "Extra #{i}", assistant: assistant, account: account)
          allow(emb).to receive(:similarity).and_return(0.85 - (i * 0.1))
          emb
        end

        allow(Aloo::Embedding).to receive(:search).and_return(embeddings, extra_embeddings)

        result = tool.execute(query: 'بحث', translated_query: 'search')

        expect(result[:results].size).to eq(5)
        similarities = result[:results].map { |r| r[:similarity] }
        expect(similarities).to eq(similarities.sort.reverse)
      end

      it 'skips translated search when translated_query matches query' do
        expect(Aloo::Embedding).to receive(:search).once.and_return([])

        tool.execute(query: 'return policy', translated_query: 'return policy')
      end

      it 'skips translated search when translated_query matches query case-insensitively' do
        expect(Aloo::Embedding).to receive(:search).once.and_return([])

        tool.execute(query: 'Return Policy', translated_query: 'return policy')
      end

      it 'falls back to single search when translated_query is nil' do
        expect(Aloo::Embedding).to receive(:search).once.and_return([])

        tool.execute(query: 'test', translated_query: nil)
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
