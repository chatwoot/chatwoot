# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Zerodb::CannedResponseSuggester, type: :service do
  let(:account) { create(:account) }
  let(:suggester) { described_class.new(account.id) }
  let(:api_url) { 'https://api.ainative.studio/v1/public' }
  let(:project_id) { 'test-project-123' }
  let(:api_key) { 'test-api-key-456' }

  before do
    stub_env('ZERODB_API_URL', api_url)
    stub_env('ZERODB_PROJECT_ID', project_id)
    stub_env('ZERODB_API_KEY', api_key)
  end

  describe '#initialize' do
    it 'sets the account_id' do
      expect(suggester.send(:account_id)).to eq(account.id)
    end

    it 'initializes embeddings_client' do
      expect(suggester.send(:embeddings_client)).to be_a(Zerodb::EmbeddingsClient)
    end

    it 'initializes vector_client' do
      expect(suggester.send(:vector_client)).to be_a(Zerodb::VectorClient)
    end
  end

  describe '#index_response' do
    let(:canned_response) { create(:canned_response, account: account, short_code: 'greeting', content: 'Hello! How can I help you?') }
    let(:embed_and_store_endpoint) { "/#{project_id}/embeddings/embed-and-store" }
    let(:expected_document_text) { "greeting: Hello! How can I help you?" }

    context 'when indexing is successful' do
      let(:response_body) do
        {
          'stored' => 1,
          'ids' => ["canned_response_#{account.id}_#{canned_response.id}"],
          'dimension' => 1536
        }
      end

      before do
        stub_request(:post, "#{api_url}#{embed_and_store_endpoint}")
          .with(
            body: hash_including(
              'documents' => array_including(
                hash_including(
                  'text' => expected_document_text,
                  'id' => "canned_response_#{account.id}_#{canned_response.id}",
                  'metadata' => hash_including(
                    'canned_response_id' => canned_response.id,
                    'account_id' => account.id,
                    'short_code' => 'greeting',
                    'content' => 'Hello! How can I help you?'
                  )
                )
              ),
              'namespace' => "canned_responses_#{account.id}",
              'model' => 'text-embedding-3-small'
            ),
            headers: {
              'X-API-Key' => api_key,
              'Content-Type' => 'application/json',
              'Accept' => 'application/json'
            }
          )
          .to_return(status: 200, body: response_body.to_json)
      end

      it 'indexes canned response using embed_and_store' do
        result = suggester.index_response(canned_response)
        expect(result['stored']).to eq(1)
        expect(result['ids']).to include("canned_response_#{account.id}_#{canned_response.id}")
      end

      it 'uses account-specific namespace' do
        suggester.index_response(canned_response)
        expect(WebMock).to have_requested(:post, "#{api_url}#{embed_and_store_endpoint}")
          .with(body: hash_including('namespace' => "canned_responses_#{account.id}"))
      end

      it 'combines short_code and content for document text' do
        suggester.index_response(canned_response)
        expect(WebMock).to have_requested(:post, "#{api_url}#{embed_and_store_endpoint}")
          .with(body: hash_including(
                  'documents' => array_including(
                    hash_including('text' => expected_document_text)
                  )
                ))
      end

      it 'includes all required metadata' do
        suggester.index_response(canned_response)
        expect(WebMock).to have_requested(:post, "#{api_url}#{embed_and_store_endpoint}")
          .with(body: hash_including(
                  'documents' => array_including(
                    hash_including(
                      'metadata' => hash_including(
                        'canned_response_id' => canned_response.id,
                        'account_id' => account.id,
                        'short_code' => 'greeting',
                        'content' => 'Hello! How can I help you?'
                      )
                    )
                  )
                ))
      end
    end

    context 'when canned_response is nil' do
      it 'raises ValidationError' do
        expect { suggester.index_response(nil) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          'Canned response cannot be nil'
        )
      end
    end

    context 'when canned_response is invalid' do
      let(:invalid_response) { build(:canned_response, account: account, content: nil) }

      it 'raises ValidationError' do
        expect { suggester.index_response(invalid_response) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          'Canned response must be valid'
        )
      end
    end

    context 'when ZeroDB API returns error' do
      before do
        stub_request(:post, "#{api_url}#{embed_and_store_endpoint}")
          .to_return(
            status: 500,
            body: { error: 'Internal server error' }.to_json
          )
      end

      it 'raises ZeroDBError and logs the error' do
        expect(Rails.logger).to receive(:error).with(/Failed to index canned response/)
        expect { suggester.index_response(canned_response) }.to raise_error(
          Zerodb::BaseService::ZeroDBError
        )
      end
    end
  end

  describe '#delete_response' do
    let(:canned_response) { create(:canned_response, account: account) }
    let(:delete_endpoint) { "/#{project_id}/vectors/delete" }
    let(:vector_id) { "canned_response_#{account.id}_#{canned_response.id}" }

    context 'when deletion is successful' do
      let(:response_body) { { 'deleted' => true, 'id' => vector_id } }

      before do
        stub_request(:delete, "#{api_url}#{delete_endpoint}")
          .with(
            body: {
              id: vector_id,
              namespace: "canned_responses_#{account.id}"
            }.to_json,
            headers: {
              'X-API-Key' => api_key,
              'Content-Type' => 'application/json',
              'Accept' => 'application/json'
            }
          )
          .to_return(status: 200, body: response_body.to_json)
      end

      it 'deletes vector from ZeroDB' do
        result = suggester.delete_response(canned_response)
        expect(result['deleted']).to be true
        expect(result['id']).to eq(vector_id)
      end

      it 'uses account-specific namespace' do
        suggester.delete_response(canned_response)
        expect(WebMock).to have_requested(:delete, "#{api_url}#{delete_endpoint}")
          .with(body: hash_including('namespace' => "canned_responses_#{account.id}"))
      end

      it 'uses correct vector_id format' do
        suggester.delete_response(canned_response)
        expect(WebMock).to have_requested(:delete, "#{api_url}#{delete_endpoint}")
          .with(body: hash_including('id' => vector_id))
      end
    end

    context 'when canned_response is nil' do
      it 'raises ValidationError' do
        expect { suggester.delete_response(nil) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          'Canned response cannot be nil'
        )
      end
    end

    context 'when canned_response has no ID' do
      let(:response_without_id) { OpenStruct.new(id: nil, account_id: account.id) }

      it 'raises ValidationError' do
        expect { suggester.delete_response(response_without_id) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          'Canned response must have an ID'
        )
      end
    end

    context 'when working with OpenStruct (after_destroy scenario)' do
      let(:deleted_response) { OpenStruct.new(id: 123, account_id: account.id, short_code: 'test') }

      before do
        stub_request(:delete, "#{api_url}#{delete_endpoint}")
          .to_return(status: 200, body: { deleted: true }.to_json)
      end

      it 'successfully deletes using OpenStruct' do
        expect { suggester.delete_response(deleted_response) }.not_to raise_error
      end
    end

    context 'when ZeroDB API returns error' do
      before do
        stub_request(:delete, "#{api_url}#{delete_endpoint}")
          .to_return(
            status: 404,
            body: { error: 'Vector not found' }.to_json
          )
      end

      it 'raises ZeroDBError and logs the error' do
        expect(Rails.logger).to receive(:error).with(/Failed to delete canned response/)
        expect { suggester.delete_response(canned_response) }.to raise_error(
          Zerodb::BaseService::ZeroDBError
        )
      end
    end
  end

  describe '#suggest' do
    let(:conversation) { create(:conversation, account: account) }
    let(:generate_endpoint) { "/#{project_id}/embeddings/generate" }
    let(:search_endpoint) { "/#{project_id}/vectors/search" }
    let(:query_vector) { Array.new(1536) { rand } }

    before do
      # Create incoming (customer) messages
      create(:message, conversation: conversation, message_type: :incoming, content: 'My account is locked', created_at: 3.minutes.ago)
      create(:message, conversation: conversation, message_type: :incoming, content: 'I cannot log in', created_at: 2.minutes.ago)
      create(:message, conversation: conversation, message_type: :incoming, content: 'Please help', created_at: 1.minute.ago)

      # Create outgoing (agent) message - should be ignored
      create(:message, conversation: conversation, message_type: :outgoing, content: 'Sure, let me help', created_at: 30.seconds.ago)
    end

    context 'when suggestions are found' do
      let!(:canned_response_1) { create(:canned_response, account: account, short_code: 'account_locked', content: 'I can help you unlock your account') }
      let!(:canned_response_2) { create(:canned_response, account: account, short_code: 'reset_password', content: 'Let me assist with password reset') }
      let!(:other_account_response) { create(:canned_response, short_code: 'other', content: 'From another account') }

      let(:search_results) do
        {
          'results' => [
            {
              'id' => "canned_response_#{account.id}_#{canned_response_1.id}",
              'score' => 0.92,
              'metadata' => {
                'canned_response_id' => canned_response_1.id,
                'account_id' => account.id,
                'short_code' => 'account_locked',
                'content' => 'I can help you unlock your account'
              }
            },
            {
              'id' => "canned_response_#{account.id}_#{canned_response_2.id}",
              'score' => 0.85,
              'metadata' => {
                'canned_response_id' => canned_response_2.id,
                'account_id' => account.id,
                'short_code' => 'reset_password',
                'content' => 'Let me assist with password reset'
              }
            }
          ],
          'count' => 2
        }
      end

      before do
        # Stub embedding generation
        stub_request(:post, "#{api_url}#{generate_endpoint}")
          .with(
            body: hash_including(
              'text' => 'My account is locked I cannot log in Please help',
              'model' => 'text-embedding-3-small'
            )
          )
          .to_return(
            status: 200,
            body: { embedding: query_vector, dimension: 1536 }.to_json
          )

        # Stub vector search
        stub_request(:post, "#{api_url}#{search_endpoint}")
          .with(
            body: hash_including(
              'query_vector' => query_vector,
              'limit' => 5,
              'namespace' => "canned_responses_#{account.id}",
              'threshold' => 0.6,
              'filters' => { 'account_id' => account.id }
            )
          )
          .to_return(status: 200, body: search_results.to_json)
      end

      it 'returns CannedResponse AR objects' do
        results = suggester.suggest(conversation)
        expect(results).to all(be_a(CannedResponse))
        expect(results.length).to eq(2)
      end

      it 'returns responses in order of similarity' do
        results = suggester.suggest(conversation)
        expect(results.first.id).to eq(canned_response_1.id)
        expect(results.second.id).to eq(canned_response_2.id)
      end

      it 'only returns responses from the same account' do
        results = suggester.suggest(conversation)
        expect(results.map(&:account_id)).to all(eq(account.id))
        expect(results.map(&:id)).not_to include(other_account_response.id)
      end

      it 'uses last 3 customer messages for context' do
        suggester.suggest(conversation)
        expect(WebMock).to have_requested(:post, "#{api_url}#{generate_endpoint}")
          .with(body: hash_including('text' => 'My account is locked I cannot log in Please help'))
      end

      it 'respects custom limit parameter' do
        suggester.suggest(conversation, limit: 3)
        expect(WebMock).to have_requested(:post, "#{api_url}#{search_endpoint}")
          .with(body: hash_including('limit' => 3))
      end

      it 'uses similarity threshold of 0.6' do
        suggester.suggest(conversation)
        expect(WebMock).to have_requested(:post, "#{api_url}#{search_endpoint}")
          .with(body: hash_including('threshold' => 0.6))
      end

      it 'filters by account_id' do
        suggester.suggest(conversation)
        expect(WebMock).to have_requested(:post, "#{api_url}#{search_endpoint}")
          .with(body: hash_including('filters' => { 'account_id' => account.id }))
      end
    end

    context 'when conversation has no customer messages' do
      let(:empty_conversation) { create(:conversation, account: account) }

      it 'returns empty array' do
        results = suggester.suggest(empty_conversation)
        expect(results).to eq([])
      end

      it 'does not call ZeroDB API' do
        suggester.suggest(empty_conversation)
        expect(WebMock).not_to have_requested(:post, "#{api_url}#{generate_endpoint}")
        expect(WebMock).not_to have_requested(:post, "#{api_url}#{search_endpoint}")
      end
    end

    context 'when conversation is nil' do
      it 'raises ValidationError' do
        expect { suggester.suggest(nil) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          'Conversation cannot be nil'
        )
      end
    end

    context 'when limit is not positive' do
      it 'raises ValidationError for zero' do
        expect { suggester.suggest(conversation, limit: 0) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          'Limit must be positive'
        )
      end

      it 'raises ValidationError for negative' do
        expect { suggester.suggest(conversation, limit: -1) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          'Limit must be positive'
        )
      end
    end

    context 'when no similar responses are found' do
      before do
        stub_request(:post, "#{api_url}#{generate_endpoint}")
          .to_return(status: 200, body: { embedding: query_vector }.to_json)

        stub_request(:post, "#{api_url}#{search_endpoint}")
          .to_return(status: 200, body: { results: [], count: 0 }.to_json)
      end

      it 'returns empty array' do
        results = suggester.suggest(conversation)
        expect(results).to eq([])
      end
    end

    context 'when ZeroDB API fails' do
      before do
        stub_request(:post, "#{api_url}#{generate_endpoint}")
          .to_return(
            status: 500,
            body: { error: 'Service unavailable' }.to_json
          )
      end

      it 'returns empty array and logs error' do
        expect(Rails.logger).to receive(:error).with(/Failed to suggest/)
        results = suggester.suggest(conversation)
        expect(results).to eq([])
      end

      it 'does not raise exception' do
        expect { suggester.suggest(conversation) }.not_to raise_error
      end
    end

    context 'when search returns deleted canned responses' do
      let!(:canned_response) { create(:canned_response, account: account) }

      let(:search_results) do
        {
          'results' => [
            {
              'id' => "canned_response_#{account.id}_999",
              'score' => 0.92,
              'metadata' => {
                'canned_response_id' => 999, # Non-existent ID
                'account_id' => account.id
              }
            }
          ]
        }
      end

      before do
        stub_request(:post, "#{api_url}#{generate_endpoint}")
          .to_return(status: 200, body: { embedding: query_vector }.to_json)

        stub_request(:post, "#{api_url}#{search_endpoint}")
          .to_return(status: 200, body: search_results.to_json)
      end

      it 'filters out non-existent responses' do
        results = suggester.suggest(conversation)
        expect(results).to be_empty
      end
    end
  end

  describe '#reindex_all' do
    let!(:canned_response_1) { create(:canned_response, account: account, short_code: 'greeting') }
    let!(:canned_response_2) { create(:canned_response, account: account, short_code: 'farewell') }
    let!(:other_account_response) { create(:canned_response, short_code: 'other') }
    let(:embed_and_store_endpoint) { "/#{project_id}/embeddings/embed-and-store" }

    context 'when reindexing is successful' do
      before do
        stub_request(:post, "#{api_url}#{embed_and_store_endpoint}")
          .to_return(status: 200, body: { stored: 1 }.to_json)
      end

      it 'indexes all account canned responses' do
        results = suggester.reindex_all
        expect(results[:total]).to eq(2)
        expect(results[:indexed]).to eq(2)
        expect(results[:failed]).to eq(0)
      end

      it 'does not index responses from other accounts' do
        suggester.reindex_all
        expect(WebMock).to have_requested(:post, "#{api_url}#{embed_and_store_endpoint}").twice
      end

      it 'returns success summary' do
        results = suggester.reindex_all
        expect(results).to include(
          total: 2,
          indexed: 2,
          failed: 0,
          errors: []
        )
      end
    end

    context 'when some indexing operations fail' do
      before do
        # First request succeeds
        stub_request(:post, "#{api_url}#{embed_and_store_endpoint}")
          .with(body: hash_including('documents' => array_including(hash_including('id' => /#{canned_response_1.id}/))))
          .to_return(status: 200, body: { stored: 1 }.to_json)

        # Second request fails
        stub_request(:post, "#{api_url}#{embed_and_store_endpoint}")
          .with(body: hash_including('documents' => array_including(hash_including('id' => /#{canned_response_2.id}/))))
          .to_return(
            status: 500,
            body: { error: 'Server error' }.to_json
          )
      end

      it 'continues indexing after failure' do
        results = suggester.reindex_all
        expect(results[:indexed]).to eq(1)
        expect(results[:failed]).to eq(1)
      end

      it 'includes error details in results' do
        results = suggester.reindex_all
        expect(results[:errors].length).to eq(1)
        expect(results[:errors].first[:id]).to eq(canned_response_2.id)
        expect(results[:errors].first[:error]).to be_present
      end
    end

    context 'when account has no canned responses' do
      let(:empty_account) { create(:account) }
      let(:empty_suggester) { described_class.new(empty_account.id) }

      it 'returns zero counts' do
        results = empty_suggester.reindex_all
        expect(results[:total]).to eq(0)
        expect(results[:indexed]).to eq(0)
      end
    end
  end

  describe 'private methods' do
    describe '#namespace_for_account' do
      it 'generates account-specific namespace' do
        namespace = suggester.send(:namespace_for_account)
        expect(namespace).to eq("canned_responses_#{account.id}")
      end
    end

    describe '#generate_vector_id' do
      let(:canned_response) { create(:canned_response, account: account) }

      it 'generates unique vector ID' do
        vector_id = suggester.send(:generate_vector_id, canned_response)
        expect(vector_id).to eq("canned_response_#{account.id}_#{canned_response.id}")
      end
    end

    describe '#build_document_text' do
      let(:canned_response) { create(:canned_response, account: account, short_code: 'test', content: 'Test content') }

      it 'combines short_code and content' do
        text = suggester.send(:build_document_text, canned_response)
        expect(text).to eq('test: Test content')
      end
    end

    describe '#build_metadata' do
      let(:canned_response) { create(:canned_response, account: account, short_code: 'test', content: 'Test content') }

      it 'includes all required fields' do
        metadata = suggester.send(:build_metadata, canned_response)
        expect(metadata).to include(
          canned_response_id: canned_response.id,
          account_id: account.id,
          short_code: 'test',
          content: 'Test content'
        )
        expect(metadata[:created_at]).to be_present
        expect(metadata[:updated_at]).to be_present
      end

      it 'formats timestamps as ISO8601' do
        metadata = suggester.send(:build_metadata, canned_response)
        expect { Time.iso8601(metadata[:created_at]) }.not_to raise_error
        expect { Time.iso8601(metadata[:updated_at]) }.not_to raise_error
      end
    end
  end
end
