# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Zerodb::SemanticSearchService do
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
    end

    context 'when credentials are present' do
      it 'initializes successfully' do
        expect { described_class.new }.not_to raise_error
      end
    end
  end

  describe '#index_conversation' do
    let(:message1) { create(:message, conversation: conversation, content: 'Customer needs help', message_type: 'incoming') }
    let(:message2) { create(:message, conversation: conversation, content: 'Agent response', message_type: 'outgoing') }

    let(:zerodb_response) do
      {
        'vector_id' => "conversation_#{account.id}_#{conversation.id}",
        'status' => 'success'
      }
    end

    before do
      message1
      message2
      stub_request(:post, %r{https://api.ainative.studio/v1/public/.*/vectors/upsert})
        .to_return(
          status: 200,
          body: zerodb_response.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    context 'with valid conversation' do
      it 'indexes conversation successfully' do
        result = service.index_conversation(conversation)

        expect(result['status']).to eq('success')
        expect(openai_client).to have_received(:embeddings).once
      end

      it 'sends correct vector data to ZeroDB' do
        service.index_conversation(conversation)

        expect(WebMock).to have_requested(:post, %r{vectors/upsert})
          .with(body: hash_including(
                  'vector_id' => "conversation_#{account.id}_#{conversation.id}",
                  'namespace' => 'conversations',
                  'metadata' => hash_including(
                    'conversation_id' => conversation.id,
                    'account_id' => account.id,
                    'inbox_id' => inbox.id
                  )
                ))
      end

      it 'includes message count in metadata' do
        service.index_conversation(conversation)

        expect(WebMock).to have_requested(:post, %r{vectors/upsert})
          .with(body: hash_including(
                  'metadata' => hash_including('message_count' => 2)
                ))
      end

      it 'generates embedding from conversation text' do
        service.index_conversation(conversation)

        expect(openai_client).to have_received(:embeddings).with(
          parameters: hash_including(
            model: 'text-embedding-3-small',
            input: a_string_including('Customer needs help', 'Agent response')
          )
        )
      end

      it 'combines messages with role labels' do
        service.index_conversation(conversation)

        expect(openai_client).to have_received(:embeddings).with(
          parameters: hash_including(
            input: a_string_matching(/Customer:.*Customer needs help.*Agent:.*Agent response/m)
          )
        )
      end
    end

    context 'with invalid conversation' do
      it 'raises ValidationError when conversation is nil' do
        expect { service.index_conversation(nil) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          /cannot be nil/
        )
      end

      it 'raises ValidationError when conversation is not persisted' do
        new_conversation = build(:conversation)
        expect { service.index_conversation(new_conversation) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          /must be persisted/
        )
      end

      it 'raises IndexingError when conversation has no messages' do
        empty_conversation = create(:conversation, account: account, inbox: inbox, contact: contact)
        expect { service.index_conversation(empty_conversation) }.to raise_error(
          Zerodb::SemanticSearchService::IndexingError,
          /no indexable content/
        )
      end
    end

    context 'when OpenAI API fails' do
      before do
        allow(openai_client).to receive(:embeddings).and_raise(StandardError.new('OpenAI API error'))
      end

      it 'raises EmbeddingGenerationError' do
        expect { service.index_conversation(conversation) }.to raise_error(
          Zerodb::SemanticSearchService::EmbeddingGenerationError,
          /Failed to generate embedding/
        )
      end
    end

    context 'when ZeroDB API fails' do
      before do
        stub_request(:post, %r{vectors/upsert})
          .to_return(status: 500, body: { error: 'Server error' }.to_json)
      end

      it 'raises IndexingError' do
        expect { service.index_conversation(conversation) }.to raise_error(
          Zerodb::SemanticSearchService::IndexingError,
          /Failed to index conversation/
        )
      end
    end

    context 'with many messages' do
      before do
        # Create 25 messages (exceeds MAX_MESSAGES_FOR_EMBEDDING of 20)
        25.times do |i|
          create(:message, conversation: conversation, content: "Message #{i}", message_type: 'incoming')
        end
      end

      it 'limits messages to MAX_MESSAGES_FOR_EMBEDDING' do
        service.index_conversation(conversation)

        # Should only use the most recent 20 messages
        request_body = WebMock.requests.last.body
        parsed_body = JSON.parse(request_body)
        message_count = parsed_body['document'].scan(/Customer:/).count

        expect(message_count).to eq(20)
      end
    end

    context 'with activity messages' do
      before do
        create(:message, conversation: conversation, content: 'Activity message', message_type: 'activity')
      end

      it 'excludes activity messages from indexing' do
        service.index_conversation(conversation)

        expect(openai_client).to have_received(:embeddings).with(
          parameters: hash_including(
            input: a_string_excluding('Activity message')
          )
        )
      end
    end
  end

  describe '#search' do
    let(:search_results) do
      {
        'results' => [
          {
            'metadata' => {
              'conversation_id' => conversation.id,
              'account_id' => account.id
            },
            'score' => 0.95
          }
        ]
      }
    end

    before do
      stub_request(:post, %r{vectors/search})
        .to_return(
          status: 200,
          body: search_results.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    context 'with valid query' do
      it 'returns conversation results' do
        results = service.search('help with payment', account_id: account.id)

        expect(results).to be_an(Array)
        expect(results.first).to eq(conversation)
      end

      it 'generates embedding for query' do
        service.search('help with payment', account_id: account.id)

        expect(openai_client).to have_received(:embeddings).with(
          parameters: hash_including(
            model: 'text-embedding-3-small',
            input: 'help with payment'
          )
        )
      end

      it 'sends correct search parameters to ZeroDB' do
        service.search('help with payment', limit: 5, filters: { account_id: account.id })

        expect(WebMock).to have_requested(:post, %r{vectors/search})
          .with(body: hash_including(
                  'limit' => 5,
                  'namespace' => 'conversations',
                  'filter_metadata' => hash_including('account_id' => account.id)
                ))
      end

      it 'applies default similarity threshold' do
        service.search('test query', filters: { account_id: account.id })

        expect(WebMock).to have_requested(:post, %r{vectors/search})
          .with(body: hash_including('threshold' => 0.7))
      end

      it 'applies custom similarity threshold' do
        service.search('test query', filters: { account_id: account.id, threshold: 0.85 })

        expect(WebMock).to have_requested(:post, %r{vectors/search})
          .with(body: hash_including('threshold' => 0.85))
      end

      it 'preserves search result order' do
        conversation2 = create(:conversation, account: account, inbox: inbox, contact: contact)
        ordered_results = {
          'results' => [
            { 'metadata' => { 'conversation_id' => conversation2.id }, 'score' => 0.95 },
            { 'metadata' => { 'conversation_id' => conversation.id }, 'score' => 0.85 }
          ]
        }

        stub_request(:post, %r{vectors/search}).to_return(
          status: 200,
          body: ordered_results.to_json
        )

        results = service.search('test', filters: { account_id: account.id })

        expect(results.map(&:id)).to eq([conversation2.id, conversation.id])
      end
    end

    context 'with filters' do
      it 'applies status filter' do
        service.search('test', filters: { account_id: account.id, status: 'open' })

        expect(WebMock).to have_requested(:post, %r{vectors/search})
          .with(body: hash_including(
                  'filter_metadata' => hash_including('status' => 'open')
                ))
      end

      it 'applies inbox_id filter' do
        service.search('test', filters: { account_id: account.id, inbox_id: inbox.id })

        expect(WebMock).to have_requested(:post, %r{vectors/search})
          .with(body: hash_including(
                  'filter_metadata' => hash_including('inbox_id' => inbox.id)
                ))
      end

      it 'applies assignee_id filter' do
        agent = create(:user, account: account)
        service.search('test', filters: { account_id: account.id, assignee_id: agent.id })

        expect(WebMock).to have_requested(:post, %r{vectors/search})
          .with(body: hash_including(
                  'filter_metadata' => hash_including('assignee_id' => agent.id)
                ))
      end
    end

    context 'with invalid parameters' do
      it 'raises ValidationError when query is blank' do
        expect { service.search('', filters: { account_id: account.id }) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          /Query cannot be blank/
        )
      end

      it 'raises ValidationError when account_id is missing' do
        expect { service.search('test query') }.to raise_error(
          Zerodb::BaseService::ValidationError,
          /Account ID is required/
        )
      end

      it 'raises ValidationError when limit is too small' do
        expect { service.search('test', limit: 0, filters: { account_id: account.id }) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          /Limit must be between 1 and 100/
        )
      end

      it 'raises ValidationError when limit is too large' do
        expect { service.search('test', limit: 101, filters: { account_id: account.id }) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          /Limit must be between 1 and 100/
        )
      end
    end

    context 'when no results found' do
      before do
        stub_request(:post, %r{vectors/search})
          .to_return(status: 200, body: { 'results' => [] }.to_json)
      end

      it 'returns empty array' do
        results = service.search('nonexistent query', filters: { account_id: account.id })

        expect(results).to eq([])
      end
    end

    context 'when ZeroDB API fails' do
      before do
        stub_request(:post, %r{vectors/search})
          .to_return(status: 500, body: { error: 'Server error' }.to_json)
      end

      it 'raises SearchError' do
        expect { service.search('test', filters: { account_id: account.id }) }.to raise_error(
          Zerodb::SemanticSearchService::SearchError,
          /Search failed/
        )
      end
    end

    context 'with account isolation' do
      let(:other_account) { create(:account) }
      let(:other_conversation) { create(:conversation, account: other_account) }

      before do
        # Mock results containing conversation from different account
        mixed_results = {
          'results' => [
            { 'metadata' => { 'conversation_id' => other_conversation.id, 'account_id' => other_account.id } }
          ]
        }
        stub_request(:post, %r{vectors/search}).to_return(status: 200, body: mixed_results.to_json)
      end

      it 'filters out conversations from other accounts' do
        results = service.search('test', filters: { account_id: account.id })

        expect(results).to be_empty
      end
    end

    context 'with performance requirements' do
      it 'completes search in less than 1 second' do
        start_time = Time.current

        service.search('test query', filters: { account_id: account.id })

        duration = Time.current - start_time
        expect(duration).to be < 1.0
      end
    end
  end

  describe '#delete_conversation' do
    before do
      stub_request(:post, %r{vectors/delete})
        .to_return(status: 200, body: { status: 'deleted' }.to_json)
    end

    context 'with valid conversation' do
      it 'deletes conversation vector from ZeroDB' do
        result = service.delete_conversation(conversation)

        expect(result).to be true
        expect(WebMock).to have_requested(:post, %r{vectors/delete})
          .with(body: hash_including(
                  'vector_id' => "conversation_#{account.id}_#{conversation.id}",
                  'namespace' => 'conversations'
                ))
      end
    end

    context 'with nil conversation' do
      it 'raises ValidationError' do
        expect { service.delete_conversation(nil) }.to raise_error(
          Zerodb::BaseService::ValidationError,
          /cannot be nil/
        )
      end
    end

    context 'when deletion fails' do
      before do
        stub_request(:post, %r{vectors/delete})
          .to_return(status: 500, body: { error: 'Server error' }.to_json)
      end

      it 'returns false and logs error' do
        result = service.delete_conversation(conversation)

        expect(result).to be false
      end
    end
  end

  describe 'private methods' do
    describe '#generate_conversation_text' do
      it 'combines messages with role labels' do
        create(:message, conversation: conversation, content: 'Hello', message_type: 'incoming')
        create(:message, conversation: conversation, content: 'Hi there', message_type: 'outgoing')

        text = service.send(:generate_conversation_text, conversation)

        expect(text).to include('Customer: Hello')
        expect(text).to include('Agent: Hi there')
      end

      it 'returns empty string for conversations without messages' do
        text = service.send(:generate_conversation_text, conversation)

        expect(text).to eq('')
      end

      it 'excludes messages without content' do
        create(:message, conversation: conversation, content: nil, message_type: 'incoming')
        create(:message, conversation: conversation, content: '', message_type: 'incoming')

        text = service.send(:generate_conversation_text, conversation)

        expect(text).to eq('')
      end
    end

    describe '#vector_id_for_conversation' do
      it 'generates unique vector ID with account and conversation ID' do
        vector_id = service.send(:vector_id_for_conversation, conversation)

        expect(vector_id).to eq("conversation_#{account.id}_#{conversation.id}")
      end
    end

    describe '#openai_api_key' do
      it 'retrieves API key from environment' do
        key = service.send(:openai_api_key)

        expect(key).to eq('test-openai-key')
      end

      it 'raises ConfigurationError when key is missing' do
        ENV.delete('OPENAI_API_KEY')

        expect { service.send(:openai_api_key) }.to raise_error(
          Zerodb::BaseService::ConfigurationError,
          /OPENAI_API_KEY/
        )
      end
    end
  end
end
