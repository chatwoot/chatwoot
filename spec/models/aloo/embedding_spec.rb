# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aloo::Embedding do
  subject(:embedding) { build(:aloo_embedding) }

  let(:account) { create(:account) }
  let(:assistant) { create(:aloo_assistant, account: account) }
  let(:document) { create(:aloo_document, assistant: assistant, account: account) }

  let(:mock_vector) { Array.new(1536) { rand(-1.0..1.0) } }
  let(:mock_embedder_result) { double('Embedder::Result', vector: mock_vector, success?: true) }
  let(:mock_batch_result) { double('Embedder::Result', vectors: [mock_vector, mock_vector, mock_vector], success?: true) }
  let(:embedder_class) { double('DocumentEmbedder') }

  before do
    stub_const('Embedders::DocumentEmbedder', embedder_class)
    allow(embedder_class).to receive(:call).and_return(mock_embedder_result)
  end

  describe 'concerns' do
    it 'includes AccountScoped' do
      expect(described_class.ancestors).to include(Aloo::AccountScoped)
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:assistant).class_name('Aloo::Assistant') }
    it { is_expected.to belong_to(:document).class_name('Aloo::Document').optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:content) }
  end

  describe 'scopes' do
    describe '.for_search' do
      let!(:with_embedding) { create(:aloo_embedding) }
      let!(:without_embedding) { create(:aloo_embedding, :without_embedding) }

      it 'returns embeddings with embedding vector' do
        expect(described_class.for_search).to include(with_embedding)
        expect(described_class.for_search).not_to include(without_embedding)
      end
    end
  end

  describe '.embed_text' do
    it 'returns nil for blank text' do
      expect(described_class.embed_text('', account: account)).to be_nil
      expect(described_class.embed_text(nil, account: account)).to be_nil
    end

    it 'calls DocumentEmbedder with text and tenant' do
      expect(embedder_class).to receive(:call)
        .with(text: 'test query', tenant: account)
        .and_return(mock_embedder_result)

      described_class.embed_text('test query', account: account)
    end

    it 'returns the vector from embedder result' do
      result = described_class.embed_text('test query', account: account)
      expect(result).to eq(mock_vector)
    end

    it 'raises RubyLLM::Error on API failure' do
      mock_response = double('Response', body: { 'error' => 'API error' })
      allow(embedder_class).to receive(:call).and_raise(RubyLLM::Error.new(mock_response))

      expect { described_class.embed_text('test', account: account) }.to raise_error(RubyLLM::Error)
    end
  end

  describe '.create_from_chunks' do
    before do
      allow(embedder_class).to receive(:call).and_return(mock_batch_result)
    end

    it 'returns empty array for blank chunks' do
      expect(described_class.create_from_chunks(chunks: [], document: document)).to eq([])
      expect(described_class.create_from_chunks(chunks: nil, document: document)).to eq([])
    end

    it 'creates embeddings for each chunk' do
      chunks = ['This is test chunk number one', 'This is test chunk number two', 'This is test chunk number three']

      expect do
        described_class.create_from_chunks(chunks: chunks, document: document)
      end.to change(described_class, :count).by(3)
    end

    it 'assigns sequential chunk indices' do
      chunks = ['This is test chunk number one', 'This is test chunk number two', 'This is test chunk number three']

      embeddings = described_class.create_from_chunks(chunks: chunks, document: document)

      expect(embeddings.map { |e| e.metadata['chunk_index'] }).to eq([0, 1, 2])
    end

    it 'stores metadata with model info' do
      chunks = ['This is a test chunk for metadata']
      batch_result = double('Embedder::Result', vectors: [mock_vector], success?: true)
      allow(embedder_class).to receive(:call).and_return(batch_result)

      embeddings = described_class.create_from_chunks(chunks: chunks, document: document)

      expect(embeddings.first.metadata['model']).to eq('text-embedding-3-small')
    end

    it 'truncates long content' do
      long_text = 'a' * 10_000
      batch_result = double('Embedder::Result', vectors: [mock_vector], success?: true)
      allow(embedder_class).to receive(:call).and_return(batch_result)

      embeddings = described_class.create_from_chunks(chunks: [long_text], document: document)

      expect(embeddings.first.content.length).to eq(described_class::MAX_TEXT_LENGTH)
    end
  end

  describe '.delete_for_document' do
    let!(:embeddings) { create_list(:aloo_embedding, 3, document: document, assistant: assistant, account: account) }
    let!(:other_embedding) { create(:aloo_embedding) }

    it 'deletes all embeddings for document' do
      expect do
        described_class.delete_for_document(document)
      end.to change(described_class, :count).by(-3)
    end

    it 'returns count of deleted records' do
      count = described_class.delete_for_document(document)
      expect(count).to eq(3)
    end

    it 'does not delete other embeddings' do
      described_class.delete_for_document(document)
      expect(described_class.exists?(other_embedding.id)).to be true
    end
  end

  describe '.reembed_document' do
    let!(:old_embeddings) { create_list(:aloo_embedding, 2, document: document, assistant: assistant, account: account) }

    before do
      allow(embedder_class).to receive(:call).and_return(mock_batch_result)
    end

    it 'deletes existing embeddings' do
      described_class.reembed_document(document: document, chunks: ['New content'])

      old_embeddings.each do |emb|
        expect(described_class.exists?(emb.id)).to be false
      end
    end

    it 'creates new embeddings' do
      new_chunks = ['This is new content chunk one', 'This is new content chunk two', 'This is new content chunk three']

      described_class.reembed_document(document: document, chunks: new_chunks)

      expect(document.embeddings.count).to eq(3)
    end
  end

  describe '.search' do
    let(:document) { create(:aloo_document, :available, assistant: assistant, account: account) }
    let!(:embedding) { create(:aloo_embedding, document: document, assistant: assistant, account: account) }

    before do
      allow(embedder_class).to receive(:call).and_return(mock_embedder_result)
    end

    it 'returns empty array for blank query' do
      expect(described_class.search('', assistant: assistant)).to eq([])
      expect(described_class.search(nil, assistant: assistant)).to eq([])
    end

    it 'calls embed_text with the query' do
      expect(described_class).to receive(:embed_text).with('test query', account: account).and_return(mock_vector)
      described_class.search('test query', assistant: assistant)
    end

    it 'returns embeddings scoped to assistant' do
      other_assistant = create(:aloo_assistant, account: account)
      other_doc = create(:aloo_document, :available, assistant: other_assistant, account: account)
      create(:aloo_embedding, document: other_doc, assistant: other_assistant, account: account)

      results = described_class.search('test', assistant: assistant)
      results.each do |result|
        expect(result.assistant).to eq(assistant)
      end
    end

    it 'filters by source_types when provided' do
      file_doc = create(:aloo_document, :available, source_type: 'file', assistant: assistant, account: account)
      create(:aloo_embedding, document: file_doc, assistant: assistant, account: account)

      results = described_class.search('test', assistant: assistant, source_types: ['file'])
      results.each do |result|
        expect(result.document.source_type).to eq('file')
      end
    end

    it 'respects limit parameter' do
      create_list(:aloo_embedding, 5, document: document, assistant: assistant, account: account)
      results = described_class.search('test', assistant: assistant, limit: 3)
      expect(results.size).to be <= 3
    end

    it 'returns empty array when embedding fails' do
      allow(described_class).to receive(:embed_text).and_return(nil)
      expect(described_class.search('test', assistant: assistant)).to eq([])
    end
  end

  describe '#similarity' do
    it 'returns nil when neighbor_distance not set' do
      embedding = build(:aloo_embedding)
      expect(embedding.similarity).to be_nil
    end
  end
end
