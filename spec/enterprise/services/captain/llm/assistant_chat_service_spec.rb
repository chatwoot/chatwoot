require 'rails_helper'

RSpec.describe Captain::Llm::AssistantChatService do
  let(:captain_assistant) { create(:captain_assistant) }
  let(:service) { described_class.new(assistant: captain_assistant) }
  let(:client) { instance_double(OpenAI::Client) }

  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
    allow(OpenAI::Client).to receive(:new).and_return(client)
  end

  describe '#generate_response' do
    let(:input) { 'How can I help you?' }
    let(:previous_messages) { [{ role: 'user', content: 'Previous message' }] }
    let(:openai_response) do
      {
        'choices' => [
          {
            'message' => {
              'content' => {
                reasoning: 'This is a helpful response',
                response: 'I can assist you with your questions.'
              }.to_json
            }
          }
        ]
      }
    end

    context 'when successful' do
      before do
        allow(client).to receive(:chat).and_return(openai_response)
      end

      it 'generates a response with input' do
        response = service.generate_response(input)
        expect(response).to eq({
                                 'reasoning' => 'This is a helpful response',
                                 'response' => 'I can assist you with your questions.'
                               })
      end

      it 'generates a response with input and previous messages' do
        response = service.generate_response(input, previous_messages)
        expect(response).to eq({
                                 'reasoning' => 'This is a helpful response',
                                 'response' => 'I can assist you with your questions.'
                               })
      end

      it 'includes previous messages in the chat parameters' do
        service.generate_response(input, previous_messages)
        expect(client).to have_received(:chat) do |params|
          messages = params[:parameters][:messages]
          expect(messages).to include(
            hash_including(role: 'user', content: 'Previous message')
          )
        end
      end

      it 'includes system message in the chat parameters' do
        service.generate_response(input)
        expect(client).to have_received(:chat) do |params|
          messages = params[:parameters][:messages]
          expect(messages.first[:role]).to eq('system')
          expect(messages.first[:content]).to include(captain_assistant.config['product_name'])
        end
      end
    end

    context 'when input is empty' do
      let(:input) { '' }

      before do
        allow(client).to receive(:chat).and_return(openai_response)
      end

      it 'does not add empty input to messages' do
        service.generate_response(input)
        expect(client).to have_received(:chat) do |params|
          messages = params[:parameters][:messages]
          expect(messages.pluck(:role)).not_to include('user')
        end
      end
    end

    context 'with documentation search' do
      let(:openai_response_with_tool) do
        {
          'choices' => [
            {
              'message' => {
                'tool_calls' => [
                  {
                    'id' => 'call_123',
                    'function' => {
                      'name' => 'search_documentation',
                      'arguments' => { 'search_query' => 'test query' }.to_json
                    }
                  }
                ]
              }
            }
          ]
        }
      end

      let(:search_results) { "Question: Test\nAnswer: Test answer" }

      before do
        allow(client).to receive(:chat).and_return(openai_response_with_tool, openai_response)
        allow(service).to receive(:fetch_documentation).and_return(search_results)
      end

      it 'handles documentation search tool calls' do
        response = service.generate_response(input)
        expect(response).to eq({
                                 'reasoning' => 'This is a helpful response',
                                 'response' => 'I can assist you with your questions.'
                               })
        expect(client).to have_received(:chat).twice
      end
    end
  end

  describe '#chat_parameters' do
    before do
      allow(client).to receive(:chat).and_return(
        {
          'choices' => [
            {
              'message' => {
                'content' => {
                  reasoning: 'Test reasoning',
                  response: 'Test response'
                }.to_json
              }
            }
          ]
        }
      )
    end

    it 'includes correct model and response format' do
      service.generate_response('test')
      expect(client).to have_received(:chat) do |params|
        parameters = params[:parameters]
        expect(parameters[:model]).to eq('gpt-4o-mini')
        expect(parameters[:response_format]).to eq({ type: 'json_object' })
        expect(parameters[:tools]).to include(
          hash_including(
            type: 'function',
            function: hash_including(name: 'search_documentation')
          )
        )
      end
    end
  end
end
