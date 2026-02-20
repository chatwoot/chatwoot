require 'rails_helper'

RSpec.describe Captain::Documents::HybridChunkSearchService do
  let(:assistant) { create(:captain_assistant) }
  let(:account) { assistant.account }
  let(:service) { described_class.new(assistant: assistant) }

  before do
    InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_OPEN_AI_API_KEY').update!(value: 'test-key')
    InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_CHUNK_RERANKING_ENABLED').update!(value: 'false')
  end

  describe '#search' do
    it 'returns no results for blank query' do
      expect(service.search('')).to eq([])
    end

    it 'returns chunk results from ready documents scoped to the assistant' do
      ready_document = create(
        :captain_document,
        account: account,
        assistant: assistant,
        status: :available,
        chunking_status: :ready
      )
      skipped_document = create(
        :captain_document,
        account: account,
        assistant: assistant,
        status: :available,
        chunking_status: :pending
      )

      create(
        :captain_document_chunk,
        document: ready_document,
        account: account,
        assistant: assistant,
        content: 'How to reset password for admins'
      )
      create(
        :captain_document_chunk,
        document: skipped_document,
        account: account,
        assistant: assistant,
        content: 'How to reset password for members'
      )

      embedding_service = instance_double(Captain::Llm::EmbeddingService, get_embedding: [])
      allow(Captain::Llm::EmbeddingService).to receive(:new).and_return(embedding_service)

      results = service.search('reset password')

      expect(results.size).to eq(1)
      expect(results.first.document_id).to eq(ready_document.id)
      expect(results.first.content).to include('reset password')
    end

    it 'uses BM25 scoring to prioritize stronger lexical matches' do
      ready_document = create(
        :captain_document,
        account: account,
        assistant: assistant,
        status: :available,
        chunking_status: :ready
      )

      weaker_chunk = create(
        :captain_document_chunk,
        document: ready_document,
        account: account,
        assistant: assistant,
        position: 0,
        content: 'Incognito mode exists for profile visibility.',
        context: 'Privacy and safety settings.'
      )
      stronger_chunk = create(
        :captain_document_chunk,
        document: ready_document,
        account: account,
        assistant: assistant,
        position: 1,
        content: 'Incognito mode allows hidden browsing. Incognito mode keeps your profile hidden.',
        context: 'Incognito mode details and hidden profile behavior.'
      )

      embedding_service = instance_double(Captain::Llm::EmbeddingService, get_embedding: [])
      allow(Captain::Llm::EmbeddingService).to receive(:new).and_return(embedding_service)

      results = service.search('how does incognito mode work')

      expect(results.first.id).to eq(stronger_chunk.id)
      expect(results.map(&:id)).to include(weaker_chunk.id)
    end

    it 'reranks RRF candidates with the configured reranker' do
      InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_CHUNK_RERANKING_ENABLED').update!(value: 'true')
      InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_CHUNK_RERANK_MODEL').update!(value: 'rerank-v4.0-pro')

      ready_document = create(
        :captain_document,
        account: account,
        assistant: assistant,
        status: :available,
        chunking_status: :ready
      )

      first_chunk = create(
        :captain_document_chunk,
        document: ready_document,
        account: account,
        assistant: assistant,
        position: 0,
        content: 'Cancel subscription from billing settings on iOS and Android.'
      )
      second_chunk = create(
        :captain_document_chunk,
        document: ready_document,
        account: account,
        assistant: assistant,
        position: 1,
        content: 'Delete your account permanently from profile settings and confirm with password.'
      )

      embedding_service = instance_double(Captain::Llm::EmbeddingService, get_embedding: [])
      allow(Captain::Llm::EmbeddingService).to receive(:new).and_return(embedding_service)

      reranker_service = instance_double(
        Captain::Documents::ChunkRerankerService,
        rerank: [second_chunk, first_chunk]
      )
      allow(Captain::Documents::ChunkRerankerService).to receive(:new).and_return(reranker_service)

      results = described_class.new(assistant: assistant).search('How do I cancel or delete my account?', limit: 2)

      expect(results.map(&:id)).to eq([second_chunk.id, first_chunk.id])
    end

    it 'falls back to RRF order when reranking fails' do
      ready_document = create(
        :captain_document,
        account: account,
        assistant: assistant,
        status: :available,
        chunking_status: :ready
      )

      create(
        :captain_document_chunk,
        document: ready_document,
        account: account,
        assistant: assistant,
        position: 0,
        content: 'Incognito mode exists for profile visibility.',
        context: 'Privacy and safety settings.'
      )
      create(
        :captain_document_chunk,
        document: ready_document,
        account: account,
        assistant: assistant,
        position: 1,
        content: 'Incognito mode allows hidden browsing. Incognito mode keeps your profile hidden.',
        context: 'Incognito mode details and hidden profile behavior.'
      )

      embedding_service = instance_double(Captain::Llm::EmbeddingService, get_embedding: [])
      allow(Captain::Llm::EmbeddingService).to receive(:new).and_return(embedding_service)

      fallback_results = described_class.new(assistant: assistant).search('how does incognito mode work', limit: 2)

      InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_CHUNK_RERANKING_ENABLED').update!(value: 'true')
      reranker_service = instance_double(Captain::Documents::ChunkRerankerService)
      allow(reranker_service).to receive(:rerank).and_raise(StandardError, 'reranker unavailable')
      allow(Captain::Documents::ChunkRerankerService).to receive(:new).and_return(reranker_service)

      reranker_failed_results = described_class.new(assistant: assistant).search('how does incognito mode work', limit: 2)

      expect(reranker_failed_results.map(&:id)).to eq(fallback_results.map(&:id))
    end
  end
end
