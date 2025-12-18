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
  end

  describe '#perform' do
    let(:message1) { create(:message, conversation: conversation, message_type: :incoming, content: 'Hello') }
    let(:message2) { create(:message, conversation: conversation, message_type: :outgoing, content: 'Hi there') }

    before do
      message1
      message2
    end

    it 'uses conversation_messages to build message history' do
      expect(service).to receive(:conversation_messages).and_call_original
      service.perform
    end

    it 'concatenates system prompt with conversation history' do
      allow(service).to receive(:prompt_from_file).with('reply').and_return('Help with reply')

      expect(service).to receive(:make_api_call) do |args|
        expected_messages = [
          { role: 'system', content: 'Help with reply' },
          { role: 'user', content: 'Hello' },
          { role: 'assistant', content: 'Hi there' }
        ]

        expect(args[:messages]).to eq(expected_messages)
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
