require 'rails_helper'
require 'ruby_llm'

RSpec.describe Captain::Llm::AssistantChatService do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account, config: { 'product_name' => 'Chatwoot' }) }
  let(:service) { described_class.new(assistant: assistant) }
  let(:chat) { instance_double(RubyLLM::Chat) }
  let(:chat_response) { instance_double(RubyLLM::Message) }
  let(:embedding) { Array.new(1536) { rand(-1.0..1.0) } }
  let(:embedding_service) { instance_double(Captain::Llm::EmbeddingService) }

  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
    allow(RubyLLM).to receive(:chat).and_return(chat)
    allow(chat).to receive(:with_tool).with(Captain::Tools::DocumentationSearch).and_return(chat)
    allow(chat).to receive(:with_instructions)
    allow(chat).to receive(:add_message)
    allow(Captain::Llm::UpdateEmbeddingJob).to receive(:perform_later)
    allow(Captain::Llm::EmbeddingService).to receive(:new).and_return(embedding_service)
    allow(embedding_service).to receive(:get_embedding).and_return(embedding)
  end

  describe '#initialize' do
    it 'sets up RubyLLM chat with DocumentationSearch tool' do
      expect(RubyLLM).to receive(:chat).with(model: anything)
      expect(chat).to receive(:with_tool).with(Captain::Tools::DocumentationSearch)
      service
    end

    it 'sets system message' do
      expect(chat).to receive(:with_instructions).with(
        Captain::Llm::SystemPromptsService.assistant_response_generator('Chatwoot')
      )
      service
    end
  end

  describe '#generate_response' do
    let(:input) { 'How do I configure inbox?' }
    let(:previous_messages) do
      [
        { role: 'user', content: 'Hello' },
        { role: 'assistant', content: 'Hi there!' }
      ]
    end

    before do
      allow(chat).to receive(:ask).and_return(chat_response)
      previous_messages.each do |msg|
        if msg[:role] == 'system'
          allow(chat).to receive(:with_instructions).with(msg[:content])
        else
          allow(chat).to receive(:add_message).with(role: msg[:role], content: msg[:content])
        end
      end
    end

    context 'when response is valid JSON' do
      let(:json_response) do
        {
          'reasoning' => 'Found in documentation',
          'response' => 'Here are the steps...'
        }
      end

      before do
        allow(chat_response).to receive(:content).and_return(json_response.to_json)
      end

      it 'returns parsed JSON response' do
        result = service.generate_response(input, previous_messages)
        expect(result).to eq(json_response)
      end
    end

    context 'when response indicates conversation handoff' do
      before do
        allow(chat_response).to receive(:content).and_return('conversation_handoff')
      end

      it 'returns conversation_handoff' do
        result = service.generate_response(input, previous_messages)
        expect(result).to eq('conversation_handoff')
      end
    end

    context 'when response is not valid JSON' do
      let(:plain_response) { 'Here are the steps...' }

      before do
        allow(chat_response).to receive(:content).and_return(plain_response)
      end

      it 'wraps response in JSON format' do
        result = service.generate_response(input, previous_messages)
        expect(result).to eq({
                               'reasoning' => '',
                               'response' => plain_response
                             })
      end
    end

    context 'when input is blank' do
      let(:input) { '' }

      it 'does not send user message' do
        expect(chat).not_to receive(:ask)
        service.generate_response(input, previous_messages)
      end
    end

    context 'when no previous messages' do
      let(:response_content) { 'Here are the steps...' }

      before do
        # Clear the service instance to avoid system message being counted
        allow(chat).to receive(:with_instructions).with(
          Captain::Llm::SystemPromptsService.assistant_response_generator('Chatwoot')
        )
        allow(chat_response).to receive(:content).and_return(response_content)
      end

      it 'only sends new input' do
        expect(chat).not_to receive(:add_message)
        expect(chat).to receive(:ask).with(input)
        service.generate_response(input)
      end
    end
  end
end
