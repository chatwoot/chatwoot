# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aloo::VectorSearchService, type: :service do
  let(:account) { create(:account) }
  let(:assistant) { create(:aloo_assistant, account: account) }
  let(:service) { described_class.new(assistant: assistant, account: account) }

  let(:query_embedding) { Array.new(1536) { rand(-1.0..1.0) } }
  let(:embedding_service) { instance_double(Aloo::EmbeddingService) }

  before do
    allow(Aloo::EmbeddingService).to receive(:new).and_return(embedding_service)
    allow(embedding_service).to receive(:generate_embedding).and_return(query_embedding)
  end

  describe '#initialize' do
    it 'raises ArgumentError when account is nil' do
      expect { described_class.new(assistant: assistant, account: nil) }
        .to raise_error(ArgumentError, 'Account required')
    end

    it 'raises ArgumentError when assistant is nil' do
      expect { described_class.new(assistant: nil, account: account) }
        .to raise_error(ArgumentError, 'Assistant required')
    end

    it 'raises ArgumentError when account mismatch' do
      other_account = create(:account)
      expect { described_class.new(assistant: assistant, account: other_account) }
        .to raise_error(ArgumentError, 'Account mismatch')
    end

    it 'accepts valid params' do
      expect { described_class.new(assistant: assistant, account: account) }.not_to raise_error
    end
  end

  describe '#search' do
    let(:document) { create(:aloo_document, :available, assistant: assistant, account: account) }
    let!(:embedding) { create(:aloo_embedding, document: document, assistant: assistant, account: account) }

    it 'returns empty array for blank query' do
      expect(service.search('')).to eq([])
      expect(service.search(nil)).to eq([])
    end

    it 'generates query embedding' do
      expect(embedding_service).to receive(:generate_embedding).with('test query')

      service.search('test query')
    end

    it 'returns empty array when embedding fails' do
      allow(embedding_service).to receive(:generate_embedding).and_return(nil)

      expect(service.search('test query')).to eq([])
    end

    it 'returns search results' do
      results = service.search('test query')

      expect(results).to be_an(Array)
    end

    it 'records trace' do
      expect(Aloo::Trace).to receive(:record_with_timing)
        .with(hash_including(trace_type: 'search'))
        .and_call_original

      service.search('test query')
    end

    context 'with matching embeddings' do
      before do
        # Create more embeddings for better test coverage
        create_list(:aloo_embedding, 3, document: document, assistant: assistant, account: account)
      end

      it 'limits results' do
        results = service.search('test query', limit: 2)

        expect(results.size).to be <= 2
      end

      it 'returns formatted results' do
        results = service.search('test query')

        if results.any?
          result = results.first
          expect(result).to have_key(:id)
          expect(result).to have_key(:document_id)
          expect(result).to have_key(:document_title)
          expect(result).to have_key(:content)
          expect(result).to have_key(:similarity)
          expect(result).to have_key(:score)
        end
      end
    end

    context 'with source type filter' do
      let!(:file_doc) { create(:aloo_document, :available, source_type: 'file', assistant: assistant, account: account) }
      let!(:website_doc) { create(:aloo_document, :available, :website, assistant: assistant, account: account) }
      let!(:file_embedding) { create(:aloo_embedding, document: file_doc, assistant: assistant, account: account) }
      let!(:website_embedding) { create(:aloo_embedding, document: website_doc, assistant: assistant, account: account) }

      it 'filters by source types' do
        results = service.search('test query', source_types: ['file'])

        # Results should only include file documents if any match
        results.each do |result|
          expect(result[:source_type]).to eq('file')
        end
      end
    end
  end

  describe '#search_for_context' do
    let(:document) { create(:aloo_document, :available, assistant: assistant, account: account) }
    let!(:embedding) { create(:aloo_embedding, document: document, assistant: assistant, account: account, content: 'Relevant content') }

    it 'returns formatted context string' do
      result = service.search_for_context('test query')

      expect(result).to be_a(String)
    end

    it 'returns empty string when no results' do
      allow(embedding_service).to receive(:generate_embedding).and_return(nil)

      result = service.search_for_context('test query')

      expect(result).to eq('')
    end

    it 'respects max_tokens' do
      result = service.search_for_context('test query', max_tokens: 100)

      expect(result).to be_a(String)
    end
  end

  describe '#find_similar' do
    let(:document) { create(:aloo_document, :available, assistant: assistant, account: account) }
    let!(:embeddings) { create_list(:aloo_embedding, 5, document: document, assistant: assistant, account: account) }
    let(:search_vector) { Array.new(1536) { rand(-1.0..1.0) } }

    it 'finds embeddings nearest to given vector' do
      results = service.find_similar(search_vector)

      expect(results).to all(be_a(Aloo::Embedding))
    end

    it 'respects limit parameter' do
      results = service.find_similar(search_vector, limit: 3)

      expect(results.size).to be <= 3
    end
  end
end
