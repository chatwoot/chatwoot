# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Zerodb::SimilarTicketDetector do
  subject(:service) { described_class.new }

  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let(:openai_client) { instance_double(OpenAI::Client) }

  # Mock embedding vector (1536 dimensions)
  let(:mock_embedding) { Array.new(1536) { rand } }
  let(:mock_openai_response) do
    { 'data' => [{ 'embedding' => mock_embedding }] }
  end

  before do
    # Set required environment variables
    ENV['ZERODB_API_KEY'] = 'test-api-key'
    ENV['ZERODB_PROJECT_ID'] = 'test-project'
    ENV['OPENAI_API_KEY'] = 'test-openai-key'

    # Mock OpenAI client
    allow(OpenAI::Client).to receive(:new).and_return(openai_client)
    allow(openai_client).to receive(:embeddings).and_return(mock_openai_response)
  end

  after do
    ENV.delete('ZERODB_API_KEY')
    ENV.delete('ZERODB_PROJECT_ID')
    ENV.delete('OPENAI_API_KEY')
  end

  describe '#initialize' do
    context 'when credentials are missing' do
      it 'raises ConfigurationError when API key is missing' do
        ENV.delete('ZERODB_API_KEY')
        expect { described_class.new }.to raise_error(
          Zerodb::BaseService::ConfigurationError,
          /ZERODB_API_KEY/
        )
      end

      it 'raises ConfigurationError when project ID is missing' do
        ENV.delete('ZERODB_PROJECT_ID')
        expect { described_class.new }.to raise_error(
          Zerodb::BaseService::ConfigurationError,
          /ZERODB_PROJECT_ID/
        )
      end

      it 'raises ConfigurationError when OpenAI key is missing during find_similar' do
        ENV.delete('OPENAI_API_KEY')
        create(:message, conversation: conversation, content: 'Test message', message_type: 'incoming')

        stub_request(:post, %r{https://api.ainative.studio/v1/public/.*/vectors/search})
          .to_return(status: 200, body: { 'results' => [] }.to_json)

        expect { service.find_similar(conversation) }.to raise_error(
          Zerodb::BaseService::ConfigurationError,
          /OPENAI_API_KEY/
        )
      end
    end

    context 'when credentials are present' do
      it 'initializes successfully' do
        expect { described_class.new }.not_to raise_error
      end
    end
  end

  describe '#find_similar' do
    let!(:message1) do
      create(:message, conversation: conversation, content: 'Customer needs refund for order #12345', message_type: 'incoming')
    end
    let!(:message2) do
      create(:message, conversation: conversation, content: 'I will process your refund', message_type: 'outgoing')
    end

    let(:similar_conversation1) { create(:conversation, account: account, inbox: inbox, contact: contact) }
    let(:similar_conversation2) { create(:conversation, account: account, inbox: inbox, contact: contact) }
    let(:similar_conversation3) { create(:conversation, account: account, inbox: inbox, contact: contact) }

    let(:zerodb_search_response) do
      {
        'results' => [
          {
            'metadata' => { 'conversation_id' => conversation.id },
            'similarity_score' => 1.0 # Self - should be excluded
          },
          {
            'metadata' => { 'conversation_id' => similar_conversation1.id },
            'similarity_score' => 0.89
          },
          {
            'metadata' => { 'conversation_id' => similar_conversation2.id },
            'similarity_score' => 0.82
          },
          {
            'metadata' => { 'conversation_id' => similar_conversation3.id },
            'similarity_score' => 0.76
          }
        ]
      }
    end

    before do
      similar_conversation1
      similar_conversation2
      similar_conversation3

      stub_request(:post, %r{https://api.ainative.studio/v1/public/.*/vectors/search})
        .to_return(
          status: 200,
          body: zerodb_search_response.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    context 'with valid inputs' do
      it 'returns similar conversations excluding self' do
        results = service.find_similar(conversation, limit: 5)

        expect(results.size).to eq(3)
        expect(results.map { |r| r[:conversation].id }).not_to include(conversation.id)
        expect(results.map { |r| r[:conversation].id }).to contain_exactly(
          similar_conversation1.id,
          similar_conversation2.id,
          similar_conversation3.id
        )
      end

      it 'includes similarity scores in results' do
        results = service.find_similar(conversation, limit: 5)

        expect(results.first[:similarity_score]).to be_a(Float)
        expect(results.first[:similarity_score]).to be_between(0.0, 1.0)
      end

      it 'orders results by similarity score (highest first)' do
        results = service.find_similar(conversation, limit: 5)

        scores = results.map { |r| r[:similarity_score] }
        expect(scores).to eq(scores.sort.reverse)
      end

      it 'respects the limit parameter' do
        results = service.find_similar(conversation, limit: 2)

        expect(results.size).to eq(2)
        expect(results.map { |r| r[:conversation].id }).to eq([
          similar_conversation1.id,
          similar_conversation2.id
        ])
      end

      it 'generates embedding from conversation messages' do
        service.find_similar(conversation, limit: 5)

        expect(openai_client).to have_received(:embeddings).with(
          parameters: hash_including(
            model: 'text-embedding-3-small',
            input: a_string_including('Customer needs refund', 'I will process your refund')
          )
        )
      end

      it 'sends correct search parameters to ZeroDB' do
        service.find_similar(conversation, limit: 3, threshold: 0.8)

        expect(WebMock).to have_requested(:post, %r{vectors/search})
          .with(body: hash_including(
                  'query_vector' => mock_embedding,
                  'limit' => 4, # +1 to account for self exclusion
                  'threshold' => 0.8,
                  'namespace' => 'conversations',
                  'filter_metadata' => hash_including('account_id' => account.id)
                ))
      end

      it 'includes account_id in metadata filters' do
        service.find_similar(conversation, limit: 5)

        expect(WebMock).to have_requested(:post, %r{vectors/search})
          .with(body: hash_including(
                  'filter_metadata' => hash_including('account_id' => account.id)
                ))
      end

      it 'preloads conversation associations' do
        results = service.find_similar(conversation, limit: 5)

        # This should not trigger N+1 queries
        expect do
          results.each do |result|
            result[:conversation].contact.name
            result[:conversation].inbox.name
            result[:conversation].assignee&.name
            result[:conversation].messages.count
          end
        end.to_not exceed_query_limit(0)
      end
    end

    context 'with custom threshold' do
      it 'uses custom similarity threshold' do
        service.find_similar(conversation, limit: 5, threshold: 0.9)

        expect(WebMock).to have_requested(:post, %r{vectors/search})
          .with(body: hash_including('threshold' => 0.9))
      end

      it 'uses default threshold when not specified' do
        service.find_similar(conversation, limit: 5)

        expect(WebMock).to have_requested(:post, %r{vectors/search})
          .with(body: hash_including('threshold' => 0.75))
      end
    end

    context 'with optional filters' do
      let(:other_inbox) { create(:inbox, account: account) }

      it 'filters by inbox_id when provided' do
        service.find_similar(conversation, limit: 5, inbox_id: other_inbox.id)

        expect(WebMock).to have_requested(:post, %r{vectors/search})
          .with(body: hash_including(
                  'filter_metadata' => hash_including('inbox_id' => other_inbox.id)
                ))
      end
    end

    context 'with invalid inputs' do
      it 'raises ValidationError when conversation is nil' do
        expect { service.find_similar(nil) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          /cannot be nil/
        )
      end

      it 'raises ValidationError when conversation is not persisted' do
        new_conversation = build(:conversation)
        expect { service.find_similar(new_conversation) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          /must be persisted/
        )
      end

      it 'raises ValidationError when limit is too low' do
        expect { service.find_similar(conversation, limit: 0) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          /Limit must be between 1 and 20/
        )
      end

      it 'raises ValidationError when limit is too high' do
        expect { service.find_similar(conversation, limit: 25) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          /Limit must be between 1 and 20/
        )
      end

      it 'raises SimilarityDetectionError when conversation has no content' do
        conversation_no_messages = create(:conversation, account: account, inbox: inbox, contact: contact)

        expect { service.find_similar(conversation_no_messages) }.to raise_error(
          Zerodb::SimilarTicketDetector::SimilarityDetectionError,
          /has no content to analyze/
        )
      end
    end

    context 'when no similar conversations are found' do
      let(:empty_response) do
        { 'results' => [{ 'metadata' => { 'conversation_id' => conversation.id }, 'similarity_score' => 1.0 }] }
      end

      before do
        stub_request(:post, %r{https://api.ainative.studio/v1/public/.*/vectors/search})
          .to_return(status: 200, body: empty_response.to_json)
      end

      it 'returns empty array' do
        results = service.find_similar(conversation, limit: 5)
        expect(results).to eq([])
      end

      it 'does not raise error' do
        expect { service.find_similar(conversation, limit: 5) }.not_to raise_error
      end
    end

    context 'when API request fails' do
      before do
        stub_request(:post, %r{https://api.ainative.studio/v1/public/.*/vectors/search})
          .to_return(status: 500, body: { error: 'Internal Server Error' }.to_json)
      end

      it 'raises SimilarityDetectionError' do
        expect { service.find_similar(conversation) }.to raise_error(
          Zerodb::SimilarTicketDetector::SimilarityDetectionError
        )
      end

      it 'logs the error' do
        allow(Rails.logger).to receive(:error)

        begin
          service.find_similar(conversation)
        rescue StandardError
          nil
        end

        expect(Rails.logger).to have_received(:error).with(
          a_string_matching(/Failed to find similar tickets/)
        )
      end
    end

    context 'when embedding generation fails' do
      before do
        allow(openai_client).to receive(:embeddings).and_raise(StandardError.new('API Error'))
      end

      it 'raises SimilarityDetectionError' do
        expect { service.find_similar(conversation) }.to raise_error(
          Zerodb::SimilarTicketDetector::SimilarityDetectionError,
          /Failed to generate embedding/
        )
      end
    end
  end

  describe '#find_similar_batch' do
    let(:conversation1) { create(:conversation, account: account, inbox: inbox, contact: contact) }
    let(:conversation2) { create(:conversation, account: account, inbox: inbox, contact: contact) }
    let(:conversations) { [conversation1, conversation2] }

    before do
      create(:message, conversation: conversation1, content: 'Test message 1', message_type: 'incoming')
      create(:message, conversation: conversation2, content: 'Test message 2', message_type: 'incoming')

      stub_request(:post, %r{https://api.ainative.studio/v1/public/.*/vectors/search})
        .to_return(status: 200, body: { 'results' => [] }.to_json)
    end

    it 'returns hash with results for each conversation' do
      results = service.find_similar_batch(conversations, limit: 5)

      expect(results).to be_a(Hash)
      expect(results.keys).to contain_exactly(conversation1.id, conversation2.id)
    end

    it 'handles individual failures gracefully' do
      allow(service).to receive(:find_similar).with(conversation1, anything).and_raise(StandardError)
      allow(service).to receive(:find_similar).with(conversation2, anything).and_return([])

      results = service.find_similar_batch(conversations, limit: 5)

      expect(results[conversation1.id]).to eq([])
      expect(results[conversation2.id]).to eq([])
    end

    it 'raises ValidationError when conversations array is empty' do
      expect { service.find_similar_batch([]) }.to raise_error(
        Zerodb::BaseService::ValidationError,
        /cannot be empty/
      )
    end
  end

  describe 'logging' do
    before do
      create(:message, conversation: conversation, content: 'Test message', message_type: 'incoming')
      stub_request(:post, %r{https://api.ainative.studio/v1/public/.*/vectors/search})
        .to_return(status: 200, body: { 'results' => [] }.to_json)
    end

    it 'logs the start of similarity detection' do
      allow(Rails.logger).to receive(:info)

      service.find_similar(conversation)

      expect(Rails.logger).to have_received(:info).with(
        a_string_matching(/Finding similar tickets for conversation #{conversation.id}/)
      )
    end

    it 'logs the completion with timing' do
      allow(Rails.logger).to receive(:info)

      service.find_similar(conversation)

      expect(Rails.logger).to have_received(:info).with(
        a_string_matching(/Found \d+ similar tickets in \d+\.\d+ms/)
      )
    end
  end

  describe 'edge cases' do
    context 'when conversation has subject in additional_attributes' do
      before do
        conversation.update(additional_attributes: { 'subject' => 'Refund Request' })
        create(:message, conversation: conversation, content: 'I need help', message_type: 'incoming')

        stub_request(:post, %r{https://api.ainative.studio/v1/public/.*/vectors/search})
          .to_return(status: 200, body: { 'results' => [] }.to_json)
      end

      it 'includes subject in embedding text' do
        service.find_similar(conversation)

        expect(openai_client).to have_received(:embeddings).with(
          parameters: hash_including(
            input: a_string_including('Subject: Refund Request')
          )
        )
      end
    end

    context 'when conversation has many messages' do
      before do
        25.times do |i|
          create(:message, conversation: conversation, content: "Message #{i}", message_type: 'incoming')
        end

        stub_request(:post, %r{https://api.ainative.studio/v1/public/.*/vectors/search})
          .to_return(status: 200, body: { 'results' => [] }.to_json)
      end

      it 'limits messages to 20 for embedding' do
        service.find_similar(conversation)

        # Should call embeddings with truncated message list
        expect(openai_client).to have_received(:embeddings)
        expect(conversation.messages.count).to eq(25)
      end
    end

    context 'when similarity scores are missing from response' do
      let(:response_without_scores) do
        {
          'results' => [
            { 'metadata' => { 'conversation_id' => similar_conversation1.id } }
          ]
        }
      end

      let(:similar_conversation1) { create(:conversation, account: account, inbox: inbox, contact: contact) }

      before do
        similar_conversation1
        stub_request(:post, %r{https://api.ainative.studio/v1/public/.*/vectors/search})
          .to_return(status: 200, body: response_without_scores.to_json)
      end

      it 'handles missing scores gracefully' do
        results = service.find_similar(conversation)

        expect(results.first[:similarity_score]).to be_nil
      end
    end
  end
end
