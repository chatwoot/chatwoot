# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aloo::EmbeddingService, type: :service do
  let(:account) { create(:account) }
  let(:assistant) { create(:aloo_assistant, account: account) }
  let(:document) { create(:aloo_document, assistant: assistant, account: account) }
  let(:service) { described_class.new(account: account) }

  let(:mock_vectors) { Array.new(1536) { rand(-1.0..1.0) } }
  let(:mock_embedding_result) { instance_double('RubyLLM::Embedding', vectors: mock_vectors) }

  before do
    allow(RubyLLM).to receive(:embed).and_return(mock_embedding_result)
  end

  describe '#initialize' do
    it 'raises error when account is nil' do
      expect { described_class.new(account: nil) }.to raise_error(ArgumentError, 'Account required')
    end

    it 'accepts valid account' do
      expect { described_class.new(account: account) }.not_to raise_error
    end
  end

  describe '#embed_and_store' do
    it 'returns nil for blank text' do
      expect(service.embed_and_store(text: '', document: document)).to be_nil
      expect(service.embed_and_store(text: nil, document: document)).to be_nil
    end

    it 'truncates long text' do
      long_text = 'a' * 10_000

      expect(RubyLLM).to receive(:embed) do |text, _opts|
        expect(text.length).to eq(described_class::MAX_TEXT_LENGTH)
        mock_embedding_result
      end

      service.embed_and_store(text: long_text, document: document)
    end

    it 'creates embedding record' do
      expect {
        service.embed_and_store(text: 'Test content', document: document)
      }.to change(Aloo::Embedding, :count).by(1)
    end

    it 'stores vector from RubyLLM' do
      embedding = service.embed_and_store(text: 'Test content', document: document)

      expect(embedding.embedding).to eq(mock_vectors)
    end

    it 'associates embedding with document and account' do
      embedding = service.embed_and_store(text: 'Test content', document: document)

      expect(embedding.document).to eq(document)
      expect(embedding.account).to eq(account)
      expect(embedding.assistant).to eq(assistant)
    end

    it 'stores metadata' do
      embedding = service.embed_and_store(text: 'Test content', document: document, chunk_index: 5)

      expect(embedding.metadata['chunk_index']).to eq(5)
      expect(embedding.metadata['model']).to eq('text-embedding-3-small')
    end

    it 'records trace' do
      expect(Aloo::Trace).to receive(:record_with_timing).and_call_original

      service.embed_and_store(text: 'Test content', document: document)
    end
  end

  describe '#batch_embed_and_store' do
    it 'returns empty array for blank texts' do
      expect(service.batch_embed_and_store(texts: [], document: document)).to eq([])
      expect(service.batch_embed_and_store(texts: nil, document: document)).to eq([])
    end

    it 'creates embeddings for each chunk' do
      texts = ['Chunk 1', 'Chunk 2', 'Chunk 3']

      expect {
        service.batch_embed_and_store(texts: texts, document: document)
      }.to change(Aloo::Embedding, :count).by(3)
    end

    it 'assigns sequential chunk indices' do
      texts = ['Chunk 1', 'Chunk 2', 'Chunk 3']

      embeddings = service.batch_embed_and_store(texts: texts, document: document)

      expect(embeddings.map { |e| e.metadata['chunk_index'] }).to eq([0, 1, 2])
    end

    it 'processes texts in batches' do
      texts = Array.new(150) { |i| "Chunk #{i}" }

      embeddings = service.batch_embed_and_store(texts: texts, document: document)

      expect(embeddings.size).to eq(150)
    end
  end

  describe '#generate_embedding' do
    it 'returns nil for blank text' do
      expect(service.generate_embedding('')).to be_nil
      expect(service.generate_embedding(nil)).to be_nil
    end

    it 'calls RubyLLM.embed with correct model' do
      expect(RubyLLM).to receive(:embed)
        .with('test query', model: 'text-embedding-3-small')
        .and_return(mock_embedding_result)

      service.generate_embedding('test query')
    end

    it 'returns vector array' do
      result = service.generate_embedding('test query')
      expect(result).to eq(mock_vectors)
    end

    it 'raises RubyLLM::Error on API failure' do
      mock_response = instance_double('Faraday::Response', body: { 'error' => 'API error' })
      allow(RubyLLM).to receive(:embed).and_raise(RubyLLM::Error.new(mock_response))

      expect { service.generate_embedding('test') }.to raise_error(RubyLLM::Error)
    end

    it 'truncates long text' do
      long_text = 'a' * 10_000

      expect(RubyLLM).to receive(:embed) do |text, _opts|
        expect(text.length).to eq(described_class::MAX_TEXT_LENGTH)
        mock_embedding_result
      end

      service.generate_embedding(long_text)
    end
  end

  describe '#generate_batch_embeddings' do
    it 'returns empty array for blank texts' do
      expect(service.generate_batch_embeddings([])).to eq([])
      expect(service.generate_batch_embeddings(nil)).to eq([])
    end

    it 'generates embeddings for each text' do
      texts = ['Text 1', 'Text 2', 'Text 3']

      expect(RubyLLM).to receive(:embed).exactly(3).times.and_return(mock_embedding_result)

      results = service.generate_batch_embeddings(texts)

      expect(results.size).to eq(3)
    end
  end

  describe '#delete_embeddings_for' do
    let!(:embeddings) { create_list(:aloo_embedding, 3, document: document, assistant: assistant, account: account) }
    let!(:other_embedding) { create(:aloo_embedding) }

    it 'deletes all embeddings for document' do
      expect {
        service.delete_embeddings_for(document)
      }.to change(Aloo::Embedding, :count).by(-3)
    end

    it 'returns count of deleted records' do
      count = service.delete_embeddings_for(document)
      expect(count).to eq(3)
    end

    it 'does not delete other embeddings' do
      service.delete_embeddings_for(document)
      expect(Aloo::Embedding.exists?(other_embedding.id)).to be true
    end
  end

  describe '#reembed' do
    let!(:old_embeddings) { create_list(:aloo_embedding, 2, document: document, assistant: assistant, account: account) }

    it 'deletes existing embeddings' do
      service.reembed(document: document, texts: ['New content'])

      old_embeddings.each do |embedding|
        expect(Aloo::Embedding.exists?(embedding.id)).to be false
      end
    end

    it 'creates new embeddings' do
      new_texts = ['New content 1', 'New content 2', 'New content 3']

      service.reembed(document: document, texts: new_texts)

      expect(document.embeddings.count).to eq(3)
    end
  end
end
