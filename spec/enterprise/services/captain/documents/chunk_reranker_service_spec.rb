require 'rails_helper'

RSpec.describe Captain::Documents::ChunkRerankerService do
  let(:assistant) { create(:captain_assistant) }
  let(:account) { assistant.account }
  let(:service) { described_class.new(account_id: account.id) }

  before do
    InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_COHERE_API_KEY').update!(value: 'cohere-test-key')
    InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_CHUNK_RERANK_MODEL').update!(value: 'rerank-v4.0-pro')
  end

  describe '#rerank' do
    it 'returns chunks in reranked order when the model returns ids' do
      document = create(:captain_document, account: account, assistant: assistant, chunking_status: :ready, status: :available)
      first_chunk = create(
        :captain_document_chunk,
        document: document,
        account: account,
        assistant: assistant,
        position: 0,
        content: 'How to cancel a subscription'
      )
      second_chunk = create(
        :captain_document_chunk,
        document: document,
        account: account,
        assistant: assistant,
        position: 1,
        content: 'How to delete an account permanently'
      )

      response_payload = {
        'results' => [
          { 'index' => 1, 'relevance_score' => 0.93 },
          { 'index' => 0, 'relevance_score' => 0.67 }
        ]
      }
      cohere_response = instance_double(
        HTTParty::Response,
        success?: true,
        code: 200,
        parsed_response: response_payload
      )
      allow(HTTParty).to receive(:post).and_return(cohere_response)

      results = service.rerank(query: 'delete account', candidates: [first_chunk, second_chunk], limit: 2)

      expect(results.map(&:id)).to eq([second_chunk.id, first_chunk.id])
    end

    it 'falls back to original order when response payload is invalid' do
      document = create(:captain_document, account: account, assistant: assistant, chunking_status: :ready, status: :available)
      first_chunk = create(
        :captain_document_chunk,
        document: document,
        account: account,
        assistant: assistant,
        position: 0,
        content: 'How to cancel a subscription'
      )
      second_chunk = create(
        :captain_document_chunk,
        document: document,
        account: account,
        assistant: assistant,
        position: 1,
        content: 'How to delete an account permanently'
      )

      cohere_response = instance_double(
        HTTParty::Response,
        success?: true,
        code: 200,
        parsed_response: { 'results' => nil }
      )
      allow(HTTParty).to receive(:post).and_return(cohere_response)

      results = service.rerank(query: 'delete account', candidates: [first_chunk, second_chunk], limit: 2)

      expect(results.map(&:id)).to eq([first_chunk.id, second_chunk.id])
    end

    it 'falls back to original order when API key is missing' do
      InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_COHERE_API_KEY').update!(value: '')

      document = create(:captain_document, account: account, assistant: assistant, chunking_status: :ready, status: :available)
      first_chunk = create(
        :captain_document_chunk,
        document: document,
        account: account,
        assistant: assistant,
        position: 0,
        content: 'How to cancel a subscription'
      )
      second_chunk = create(
        :captain_document_chunk,
        document: document,
        account: account,
        assistant: assistant,
        position: 1,
        content: 'How to delete an account permanently'
      )

      results = described_class.new(account_id: account.id).rerank(
        query: 'delete account',
        candidates: [first_chunk, second_chunk],
        limit: 2
      )

      expect(results.map(&:id)).to eq([first_chunk.id, second_chunk.id])
    end
  end
end
