require 'rails_helper'

RSpec.describe Captain::AssistantResponse do
  describe '.search' do
    let(:embedding_service) { instance_double(Captain::Llm::EmbeddingService) }
    let(:embedding) { Array.new(1536, 0.1) }

    it 'passes the search path and available metadata to the embedding service' do
      allow(Captain::Llm::EmbeddingService).to receive(:new).with(account_id: 1).and_return(embedding_service)
      allow(embedding_service).to receive(:get_embedding).and_return(embedding)
      allow(described_class).to receive(:nearest_neighbors).and_return(described_class.none)

      described_class.search(
        'reset password',
        account_id: 1,
        embedding_source: 'faq_lookup',
        embedding_metadata: { assistant_id: 2 }
      ).to_a

      expect(embedding_service).to have_received(:get_embedding).with(
        'reset password',
        purpose: 'search',
        source: 'faq_lookup',
        metadata: { assistant_id: 2 }
      )
    end
  end
end
