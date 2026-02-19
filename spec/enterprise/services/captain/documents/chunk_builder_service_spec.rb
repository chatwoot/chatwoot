require 'rails_helper'

RSpec.describe Captain::Documents::ChunkBuilderService do
  let(:document) { create(:captain_document, status: :available, content: 'Pricing and limits content') }
  let(:chunking_service) { instance_double(Captain::Documents::ChunkingService) }
  let(:embedding_service) { instance_double(Captain::Documents::ChunkEmbeddingService) }
  let(:context_service) { instance_double(Captain::Documents::ContextGenerationService) }
  let(:chunks) do
    [
      { position: 0, content: 'Chunk 1', token_count: 10 },
      { position: 1, content: 'Chunk 2', token_count: 12 }
    ]
  end
  let(:embedding_vector) { Array.new(1536, 0.1) }

  before do
    allow(Captain::Documents::ChunkingService).to receive(:new).and_return(chunking_service)
    allow(chunking_service).to receive(:chunk).and_return(chunks)

    allow(Captain::Documents::ChunkEmbeddingService).to receive(:new).and_return(embedding_service)
    allow(embedding_service).to receive(:build_record_attributes) do |args|
      chunk = args.fetch(:chunk)
      {
        document_id: document.id,
        assistant_id: document.assistant_id,
        account_id: document.account_id,
        position: chunk.fetch(:position),
        content: chunk.fetch(:content),
        token_count: chunk[:token_count],
        context: args[:context],
        embedding: embedding_vector,
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    allow(Captain::Documents::ContextGenerationService).to receive(:new).and_return(context_service)
    allow(context_service).to receive(:generate).and_return('Chunk context')
  end

  describe '#process' do
    it 'builds chunks and marks the document ready with progress counters' do
      described_class.new(document).process

      document.reload
      expect(document.chunking_status).to eq('ready')
      expect(document.expected_chunk_count).to eq(2)
      expect(document.indexed_chunk_count).to eq(2)
      expect(document.chunks_generated_at).to be_present
      expect(document.last_chunk_error).to be_nil
      expect(document.chunks.count).to eq(2)
    end

    it 'replaces existing chunks when reprocessed (idempotent rebuild)' do
      create(
        :captain_document_chunk,
        document: document,
        assistant: document.assistant,
        account: document.account,
        position: 99,
        embedding: nil
      )

      described_class.new(document).process

      positions = document.chunks.reload.order(:position).pluck(:position)
      expect(positions).to eq([0, 1])
    end

    it 'marks the document failed and stores the error when processing fails' do
      allow(chunking_service).to receive(:chunk).and_raise(StandardError, 'chunking failed')

      expect { described_class.new(document).process }.to raise_error(StandardError, 'chunking failed')

      document.reload
      expect(document.chunking_status).to eq('failed')
      expect(document.last_chunk_error).to eq('chunking failed')
    end
  end
end
