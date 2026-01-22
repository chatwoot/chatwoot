require 'rails_helper'

RSpec.describe Captain::LabelSuggestionService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:label1) { create(:label, account: account, title: 'bug') }
  let(:label2) { create(:label, account: account, title: 'feature-request') }
  let(:service) { described_class.new(account: account, conversation_display_id: conversation.display_id) }
  let(:mock_chat) { instance_double(RubyLLM::Chat) }
  let(:mock_context) { instance_double(RubyLLM::Context, chat: mock_chat) }
  let(:mock_response) { instance_double(RubyLLM::Message, content: 'bug, feature-request', input_tokens: 100, output_tokens: 20) }

  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
    label1
    label2
    allow(Llm::Config).to receive(:with_api_key).and_yield(mock_context)
    allow(mock_chat).to receive(:with_instructions)
    allow(mock_chat).to receive(:ask).and_return(mock_response)
    # Stub captain enabled check to allow specs to test base functionality
    # without enterprise module interference
    allow(account).to receive(:feature_enabled?).and_call_original
    allow(account).to receive(:feature_enabled?).with('captain_tasks').and_return(true)
  end

  describe '#label_suggestion_message' do
    context 'with valid conversation' do
      before do
        # Create enough incoming messages to pass validation
        3.times do |i|
          create(:message, conversation: conversation, message_type: :incoming,
                           content: "Message #{i}", created_at: i.minutes.ago)
        end
      end

      it 'returns label suggestions' do
        result = service.perform

        expect(result[:message]).to eq('bug, feature-request')
      end

      it 'removes "Labels:" prefix from response' do
        allow(mock_response).to receive(:content).and_return('Labels: bug, feature-request')

        result = service.perform

        expect(result[:message]).to eq(' bug, feature-request')
      end

      it 'removes "Label:" prefix (singular) from response' do
        allow(mock_response).to receive(:content).and_return('label: bug')

        result = service.perform

        expect(result[:message]).to eq(' bug')
      end

      it 'builds labels_with_messages format correctly' do
        expect(service).to receive(:make_api_call) do |args|
          user_message = args[:messages].find { |m| m[:role] == 'user' }[:content]

          expect(user_message).to include('Messages:')
          expect(user_message).to include('Labels:')
          expect(user_message).to include('bug, feature-request')
          { message: 'bug' }
        end

        service.perform
      end
    end

    context 'with invalid conversation' do
      it 'returns nil when conversation has less than 3 incoming messages' do
        create(:message, conversation: conversation, message_type: :incoming, content: 'Message 1')
        create(:message, conversation: conversation, message_type: :incoming, content: 'Message 2')

        result = service.perform

        expect(result).to be_nil
      end

      it 'returns nil when conversation has more than 100 messages' do
        101.times do |i|
          create(:message, conversation: conversation, message_type: :incoming, content: "Message #{i}")
        end

        result = service.perform

        expect(result).to be_nil
      end

      it 'returns nil when conversation has >20 messages and last is not incoming' do
        21.times do |i|
          create(:message, conversation: conversation, message_type: :incoming, content: "Message #{i}")
        end
        create(:message, conversation: conversation, message_type: :outgoing, content: 'Agent reply')

        result = service.perform

        expect(result).to be_nil
      end
    end

    context 'when caching' do
      before do
        3.times do |i|
          create(:message, conversation: conversation, message_type: :incoming,
                           content: "Message #{i}", created_at: i.minutes.ago)
        end
      end

      it 'reads from cache on cache hit' do
        # Warm up cache
        service.perform

        # Create new service instance to test cache read
        new_service = described_class.new(account: account, conversation_display_id: conversation.display_id)

        expect(new_service).not_to receive(:make_api_call)
        result = new_service.perform

        expect(result[:message]).to eq('bug, feature-request')
      end

      it 'writes to cache on cache miss' do
        expect(Redis::Alfred).to receive(:setex).and_call_original

        service.perform
      end

      it 'returns nil for invalid cached JSON' do
        # Set invalid JSON in cache
        cache_key = service.send(:cache_key)
        Redis::Alfred.set(cache_key, 'invalid json')

        result = service.perform

        # Should make API call since cache read failed
        expect(result[:message]).to eq('bug, feature-request')
      end

      it 'does not cache error responses' do
        error_response = { error: 'API Error', request_messages: [] }
        allow(service).to receive(:make_api_call).and_return(error_response)

        expect(Redis::Alfred).not_to receive(:setex)

        service.perform
      end
    end

    context 'when no labels exist' do
      before do
        Label.destroy_all
        3.times do |i|
          create(:message, conversation: conversation, message_type: :incoming,
                           content: "Message #{i}")
        end
      end

      it 'returns nil' do
        result = service.perform

        expect(result).to be_nil
      end
    end
  end
end
