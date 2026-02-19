require 'rails_helper'

RSpec.describe Captain::Documents::ChunkEmbeddingService do
  let(:embedding_service) { instance_double(Captain::Llm::EmbeddingService) }

  before do
    allow(Captain::Llm::EmbeddingService).to receive(:new).with(account_id: 7).and_return(embedding_service)
    allow(embedding_service).to receive(:get_embedding).and_return([0.1, 0.2, 0.3])
  end

  describe '#embed' do
    it 'embeds combined context and content when both are present' do
      service = described_class.new(account_id: 7)

      result = service.embed(content: 'Starts at $19', context: 'Pricing page')

      expect(result).to eq([0.1, 0.2, 0.3])
      expect(embedding_service).to have_received(:get_embedding).with("Pricing page\n\nStarts at $19")
    end

    it 'returns empty embedding when both content and context are blank' do
      service = described_class.new(account_id: 7)

      result = service.embed(content: '', context: nil)

      expect(result).to eq([])
      expect(embedding_service).not_to have_received(:get_embedding)
    end
  end

  describe '#build_record_attributes' do
    it 'returns attributes ready for persisting a document chunk record' do
      document = instance_double(Captain::Document, id: 10, assistant_id: 11, account_id: 7)
      chunk = { position: 3, content: 'Chunk body', token_count: 42 }

      service = described_class.new(account_id: 7)
      result = service.build_record_attributes(document: document, chunk: chunk, context: 'Chunk context')

      expect(result).to include(
        document_id: 10,
        assistant_id: 11,
        account_id: 7,
        position: 3,
        content: 'Chunk body',
        token_count: 42,
        context: 'Chunk context',
        embedding: [0.1, 0.2, 0.3]
      )
      expect(result[:created_at]).to be_present
      expect(result[:updated_at]).to be_present
    end
  end
end
