require 'rails_helper'

RSpec.describe Captain::Llm::AssistantChatService do
  let(:captain_assistant) { create(:captain_assistant) }
  let(:service) { described_class.new(assistant: captain_assistant) }
  let(:client) { instance_double(OpenAI::Client) }
  let(:input) { 'How can I help you?' }
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

  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
    allow(OpenAI::Client).to receive(:new).and_return(client)
    allow(client).to receive(:chat).and_return(openai_response)
  end

  describe '#generate_response' do
    context 'when successful' do
      it 'generates a response with input' do
        response = service.generate_response(input)
        expect(response).to eq({
                                 'reasoning' => 'This is a helpful response',
                                 'response' => 'I can assist you with your questions.'
                               })
      end

      it 'generates a response with input and previous messages' do
        previous_messages = [{ role: 'user', content: 'Previous message' }]
        response = service.generate_response(input, previous_messages)
        expect(response).to eq({
                                 'reasoning' => 'This is a helpful response',
                                 'response' => 'I can assist you with your questions.'
                               })
      end

      it 'includes previous messages in the chat parameters' do
        previous_messages = [{ role: 'user', content: 'Previous message' }]
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

    context 'when search fails' do
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

      before do
        allow(client).to receive(:chat)
          .and_return(openai_response_with_tool)
        allow(captain_assistant.responses).to receive(:approved).and_return(captain_assistant.responses)
        allow(captain_assistant.responses).to receive(:search)
          .and_raise(StandardError, 'Search failed')
      end

      it 'raises the error' do
        expect { service.generate_response(input) }.to raise_error(StandardError, 'Search failed')
      end
    end

    context 'with invalid tool parameters' do
      let(:openai_response_with_invalid_tool) do
        {
          'choices' => [
            {
              'message' => {
                'tool_calls' => [
                  {
                    'id' => 'call_123',
                    'function' => {
                      'name' => 'search_documentation',
                      'arguments' => 'invalid_json'
                    }
                  }
                ]
              }
            }
          ]
        }
      end

      before do
        allow(client).to receive(:chat)
          .and_return(openai_response_with_invalid_tool)
      end

      it 'raises JSON::ParserError' do
        expect { service.generate_response(input) }.to raise_error(JSON::ParserError)
      end
    end

    context 'with model configuration' do
      it 'uses the configured model' do
        service.generate_response(input)
        expect(client).to have_received(:chat) do |params|
          expect(params[:parameters][:model]).to eq('gpt-4o-mini')
        end
      end

      it 'includes json response format' do
        service.generate_response(input)
        expect(client).to have_received(:chat) do |params|
          expect(params[:parameters][:response_format]).to eq({ type: 'json_object' })
        end
      end
    end
  end

  describe '#initialize' do
    it 'configures search_documentation tool' do
      service.generate_response(input)
      expect(client).to have_received(:chat) do |params|
        tools = params[:parameters][:tools]
        expect(tools).to contain_exactly(
          hash_including(
            type: 'function',
            function: hash_including(
              name: 'search_documentation',
              description: match(/documentation/),
              parameters: hash_including(
                type: 'object',
                properties: hash_including(
                  search_query: hash_including(
                    type: 'string',
                    description: match(/search query/)
                  )
                ),
                required: ['search_query']
              )
            )
          )
        )
      end
    end

    it 'provides access to assistant configuration' do
      service.generate_response(input)
      expect(client).to have_received(:chat) do |params|
        messages = params[:parameters][:messages]
        system_message = messages.find { |m| m[:role] == 'system' }
        expect(system_message[:content]).to include(captain_assistant.config['product_name'])
      end
    end
  end

  describe '#chat_parameters' do
    it 'includes correct model and response format' do
      service.generate_response(input)
      expect(client).to have_received(:chat) do |params|
        parameters = params[:parameters]
        expect(parameters[:model]).to eq('gpt-4o-mini')
        expect(parameters[:response_format]).to eq({ type: 'json_object' })
      end
    end
  end
end
