require 'rails_helper'

RSpec.describe Captain::ReplySuggestionService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:service) { described_class.new(account: account, conversation_display_id: conversation.display_id) }
  let(:mock_chat) { instance_double(RubyLLM::Chat) }
  let(:mock_context) { instance_double(RubyLLM::Context, chat: mock_chat) }
  let(:mock_response) { instance_double(RubyLLM::Message, content: 'Suggested reply', input_tokens: 100, output_tokens: 50) }

  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
    allow(Llm::Config).to receive(:with_api_key).and_yield(mock_context)
    allow(mock_chat).to receive(:with_instructions)
    allow(mock_chat).to receive(:add_message)
    allow(mock_chat).to receive(:ask).and_return(mock_response)
    # Stub captain enabled check to allow specs to test base functionality
    # without enterprise module interference
    allow(account).to receive(:feature_enabled?).and_call_original
    allow(account).to receive(:feature_enabled?).with('captain_tasks').and_return(true)
  end

  describe '#perform' do
    let(:message1) { create(:message, conversation: conversation, message_type: :incoming, content: 'Hello') }
    let(:message2) { create(:message, conversation: conversation, message_type: :outgoing, content: 'Hi there') }

    before do
      message1
      message2
    end

    it 'uses LlmFormatter to build conversation context' do
      expect(LlmFormatter::ConversationLlmFormatter).to receive(:new).with(conversation).and_call_original
      service.perform
    end

    it 'sends system prompt and formatted conversation as messages' do
      allow(service).to receive(:prompt_from_file).with('reply').and_return('Help with reply')

      expect(service).to receive(:make_api_call) do |args|
        expect(args[:messages].length).to eq(2)
        expect(args[:messages][0]).to eq({ role: 'system', content: 'Help with reply' })
        expect(args[:messages][1][:role]).to eq('user')
        expect(args[:messages][1][:content]).to include('Message History:')
        expect(args[:messages][1][:content]).to include('User: Hello')
        expect(args[:messages][1][:content]).to include('Support Agent: Hi there')
        { message: 'Suggested reply' }
      end

      service.perform
    end

    it 'passes correct model to API' do
      expect(service).to receive(:make_api_call).with(
        hash_including(model: Captain::BaseTaskService::GPT_MODEL)
      ).and_call_original

      service.perform
    end

    it 'returns formatted response' do
      result = service.perform

      expect(result[:message]).to eq('Suggested reply')
      expect(result[:usage]['prompt_tokens']).to eq(100)
      expect(result[:usage]['completion_tokens']).to eq(50)
    end
  end
end
