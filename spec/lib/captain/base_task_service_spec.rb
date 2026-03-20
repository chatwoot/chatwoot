require 'rails_helper'

RSpec.describe Captain::BaseTaskService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }

  # Create a concrete test service class since BaseTaskService is abstract
  let(:test_service_class) do
    Class.new(described_class) do
      def perform
        { message: 'Test response' }
      end

      def event_name
        'test_event'
      end
    end
  end

  let(:service) { test_service_class.new(account: account, conversation_display_id: conversation.display_id) }

  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
    # Stub captain enabled check to allow OSS specs to test base functionality
    # without enterprise module interference
    allow(account).to receive(:feature_enabled?).and_call_original
    allow(account).to receive(:feature_enabled?).with('captain_tasks').and_return(true)
  end

  describe '#perform' do
    it 'returns the expected result' do
      result = service.perform
      expect(result).to eq({ message: 'Test response' })
    end
  end

  describe '#event_name' do
    it 'raises NotImplementedError for base class' do
      base_service = described_class.new(account: account, conversation_display_id: conversation.display_id)
      expect { base_service.send(:event_name) }.to raise_error(NotImplementedError, /must implement #event_name/)
    end

    it 'returns custom event name in subclass' do
      expect(service.send(:event_name)).to eq('test_event')
    end
  end

  describe '#conversation' do
    it 'finds conversation by display_id' do
      expect(service.send(:conversation)).to eq(conversation)
    end

    it 'memoizes the conversation' do
      expect(account.conversations).to receive(:find_by).once.and_return(conversation)
      service.send(:conversation)
      service.send(:conversation)
    end
  end

  describe '#conversation_messages' do
    let(:message1) { create(:message, conversation: conversation, message_type: :incoming, content: 'Hello', created_at: 1.hour.ago) }
    let(:message2) { create(:message, conversation: conversation, message_type: :outgoing, content: 'Hi there', created_at: 30.minutes.ago) }
    let(:message3) { create(:message, conversation: conversation, message_type: :incoming, content: 'How are you?', created_at: 10.minutes.ago) }
    let(:private_message) { create(:message, conversation: conversation, message_type: :incoming, content: 'Private', private: true) }

    before do
      message1
      message2
      message3
      private_message
    end

    it 'returns messages in array format with role and content' do
      messages = service.send(:conversation_messages)

      expect(messages).to be_an(Array)
      expect(messages.length).to eq(3)
      expect(messages[0]).to eq({ role: 'user', content: 'Hello' })
      expect(messages[1]).to eq({ role: 'assistant', content: 'Hi there' })
      expect(messages[2]).to eq({ role: 'user', content: 'How are you?' })
    end

    it 'excludes private messages' do
      messages = service.send(:conversation_messages)
      contents = messages.pluck(:content)
      expect(contents).not_to include('Private')
    end

    it 'respects token limit' do
      # Create messages that collectively exceed token limit
      # Message validation max is 150000, so create multiple large messages
      10.times do |i|
        create(:message, conversation: conversation, message_type: :incoming,
                         content: 'a' * 100_000, created_at: i.minutes.ago)
      end

      messages = service.send(:conversation_messages)
      total_length = messages.sum { |m| m[:content].length }
      expect(total_length).to be <= Captain::BaseTaskService::TOKEN_LIMIT
    end

    it 'respects start_from offset for token counting' do
      # With a start_from offset, fewer messages should fit
      start_from = Captain::BaseTaskService::TOKEN_LIMIT - 100
      messages = service.send(:conversation_messages, start_from: start_from)

      total_length = messages.sum { |m| m[:content].length }
      expect(total_length).to be <= 100
    end
  end

  describe '#make_api_call' do
    let(:model) { 'gpt-4' }
    let(:messages) { [{ role: 'system', content: 'Test' }, { role: 'user', content: 'Hello' }] }
    let(:mock_chat) { instance_double(RubyLLM::Chat) }
    let(:mock_context) { instance_double(RubyLLM::Context, chat: mock_chat) }
    let(:mock_response) { instance_double(RubyLLM::Message, content: 'Response', input_tokens: 10, output_tokens: 20) }

    before do
      allow(Llm::Config).to receive(:with_api_key).and_yield(mock_context)
      allow(mock_chat).to receive(:with_instructions)
      allow(mock_chat).to receive(:ask).and_return(mock_response)
    end

    context 'when captain_tasks is disabled' do
      before do
        allow(account).to receive(:feature_enabled?).with('captain_tasks').and_return(false)
      end

      it 'returns disabled error' do
        result = service.send(:make_api_call, model: model, messages: messages)

        expect(result[:error]).to eq(I18n.t('captain.disabled'))
        expect(result[:error_code]).to eq(403)
      end

      it 'does not make API call' do
        expect(Llm::Config).not_to receive(:with_api_key)
        service.send(:make_api_call, model: model, messages: messages)
      end
    end

    context 'when API key is not configured' do
      before do
        InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.destroy!
        # Clear memoized api_key
        service.instance_variable_set(:@api_key, nil)
      end

      it 'returns api key missing error' do
        result = service.send(:make_api_call, model: model, messages: messages)

        expect(result[:error]).to eq(I18n.t('captain.api_key_missing'))
        expect(result[:error_code]).to eq(401)
      end

      it 'does not make API call' do
        expect(Llm::Config).not_to receive(:with_api_key)
        service.send(:make_api_call, model: model, messages: messages)
      end
    end

    it 'instruments the LLM call' do
      expect(service).to receive(:instrument_llm_call).and_call_original
      service.send(:make_api_call, model: model, messages: messages)
    end

    it 'returns formatted response with tokens' do
      result = service.send(:make_api_call, model: model, messages: messages)

      expect(result[:message]).to eq('Response')
      expect(result[:usage]['prompt_tokens']).to eq(10)
      expect(result[:usage]['completion_tokens']).to eq(20)
      expect(result[:usage]['total_tokens']).to eq(30)
    end
  end

  describe 'chat setup' do
    let(:model) { 'gpt-4' }
    let(:mock_chat) { instance_double(RubyLLM::Chat) }
    let(:mock_context) { instance_double(RubyLLM::Context, chat: mock_chat) }
    let(:mock_response) { instance_double(RubyLLM::Message, content: 'Response', input_tokens: 10, output_tokens: 20) }

    before do
      allow(Llm::Config).to receive(:with_api_key).and_yield(mock_context)
      allow(mock_response).to receive(:input_tokens).and_return(10)
      allow(mock_response).to receive(:output_tokens).and_return(20)
    end

    context 'with system instructions' do
      let(:messages) { [{ role: 'system', content: 'You are helpful' }, { role: 'user', content: 'Hello' }] }

      it 'applies system instructions to chat' do
        expect(mock_chat).to receive(:with_instructions).with('You are helpful')
        expect(mock_chat).to receive(:ask).with('Hello').and_return(mock_response)

        service.send(:make_api_call, model: model, messages: messages)
      end
    end

    context 'with conversation history' do
      let(:messages) do
        [
          { role: 'system', content: 'You are helpful' },
          { role: 'user', content: 'First message' },
          { role: 'assistant', content: 'First response' },
          { role: 'user', content: 'Second message' }
        ]
      end

      it 'adds conversation history before asking' do
        expect(mock_chat).to receive(:with_instructions).with('You are helpful')
        expect(mock_chat).to receive(:add_message).with(role: :user, content: 'First message').ordered
        expect(mock_chat).to receive(:add_message).with(role: :assistant, content: 'First response').ordered
        expect(mock_chat).to receive(:ask).with('Second message').and_return(mock_response)

        service.send(:make_api_call, model: model, messages: messages)
      end
    end

    context 'with single message' do
      let(:messages) { [{ role: 'system', content: 'You are helpful' }, { role: 'user', content: 'Hello' }] }

      it 'does not add conversation history' do
        expect(mock_chat).to receive(:with_instructions).with('You are helpful')
        expect(mock_chat).not_to receive(:add_message)
        expect(mock_chat).to receive(:ask).with('Hello').and_return(mock_response)

        service.send(:make_api_call, model: model, messages: messages)
      end
    end
  end

  describe 'error handling' do
    let(:model) { 'gpt-4' }
    let(:messages) { [{ role: 'user', content: 'Hello' }] }
    let(:error) { StandardError.new('API Error') }
    let(:exception_tracker) { instance_double(ChatwootExceptionTracker) }

    before do
      allow(Llm::Config).to receive(:with_api_key).and_raise(error)
      allow(ChatwootExceptionTracker).to receive(:new).with(error, account: account).and_return(exception_tracker)
      allow(exception_tracker).to receive(:capture_exception)
    end

    it 'tracks exceptions' do
      expect(ChatwootExceptionTracker).to receive(:new).with(error, account: account).and_return(exception_tracker)
      expect(exception_tracker).to receive(:capture_exception)

      service.send(:make_api_call, model: model, messages: messages)
    end

    it 'returns error response' do
      expect(exception_tracker).to receive(:capture_exception)
      result = service.send(:make_api_call, model: model, messages: messages)

      expect(result[:error]).to eq('API Error')
      expect(result[:request_messages]).to eq(messages)
    end
  end

  describe '#api_key' do
    context 'when openai hook is configured' do
      let(:hook) { create(:integrations_hook, account: account, app_id: 'openai', status: 'enabled', settings: { 'api_key' => 'hook-key' }) }

      before { hook }

      it 'uses api key from hook' do
        expect(service.send(:api_key)).to eq('hook-key')
      end
    end

    context 'when openai hook is not configured' do
      it 'uses system api key' do
        expect(service.send(:api_key)).to eq('test-key')
      end
    end
  end

  describe '#prompt_from_file' do
    it 'reads prompt from file' do
      allow(Rails.root).to receive(:join).and_return(instance_double(Pathname, read: 'Test prompt content'))
      expect(service.send(:prompt_from_file, 'test')).to eq('Test prompt content')
    end
  end

  describe '#extract_original_context' do
    it 'returns the most recent user message' do
      messages = [
        { role: 'user', content: 'First question' },
        { role: 'assistant', content: 'First response' },
        { role: 'user', content: 'Follow-up question' }
      ]

      result = service.send(:extract_original_context, messages)
      expect(result).to eq('Follow-up question')
    end

    it 'returns nil when no user messages exist' do
      messages = [
        { role: 'system', content: 'System prompt' },
        { role: 'assistant', content: 'Response' }
      ]

      result = service.send(:extract_original_context, messages)
      expect(result).to be_nil
    end

    it 'returns the only user message when there is just one' do
      messages = [
        { role: 'system', content: 'System prompt' },
        { role: 'user', content: 'Single question' }
      ]

      result = service.send(:extract_original_context, messages)
      expect(result).to eq('Single question')
    end
  end
end
