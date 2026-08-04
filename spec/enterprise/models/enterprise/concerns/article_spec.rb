require 'rails_helper'

RSpec.describe Enterprise::Concerns::Article do
  describe '.vector_search' do
    let(:embedding_service) { instance_double(Captain::Llm::EmbeddingService) }

    it 'identifies help center searches and includes the language' do
      allow(Captain::Llm::EmbeddingService).to receive(:new).with(account_id: 1).and_return(embedding_service)
      allow(embedding_service).to receive(:get_embedding).and_return(Array.new(1536, 0.1))
      allow(ArticleEmbedding).to receive(:where).and_return(ArticleEmbedding.none)

      params = { 'query' => 'reset password' }.merge(account_id: 1, locale: 'es')
      Article.vector_search(params).to_a

      expect(embedding_service).to have_received(:get_embedding).with(
        'reset password',
        purpose: 'search',
        source: 'help_center_search',
        metadata: { language: 'es' }
      )
    end
  end
end
