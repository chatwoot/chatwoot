require 'rails_helper'

RSpec.describe Captain::Documents::HybridChunkSearchService do
  let(:assistant) { create(:captain_assistant) }
  let(:account) { assistant.account }
  let(:service) { described_class.new(assistant: assistant) }

  before do
    InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_OPEN_AI_API_KEY').update!(value: 'test-key')
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
  end
end
