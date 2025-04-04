require 'rails_helper'

RSpec.describe Captain::Llm::AssistantChatService do
  let(:captain_assistant) { create(:captain_assistant) }
  let(:service) { described_class.new(assistant: captain_assistant) }
  let(:client) { instance_double(OpenAI::Client) }
  let(:input) { 'How can I help you?' }

  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
    allow(OpenAI::Client).to receive(:new).and_return(client)
  end

  describe '#generate_response' do
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

      it 'includes documentation search tool in chat parameters' do
        service.generate_response(input)
        expect(client).to have_received(:chat) do |params|
          tools = params[:parameters][:tools]
          expect(tools).to contain_exactly(
            hash_including(
              type: 'function',
              function: hash_including(
                name: 'search_documentation',
                parameters: hash_including(
                  properties: hash_including(
                    search_query: hash_including(type: 'string')
                  )
                )
              )
            )
          )
        end
      end

      it 'includes json response format in chat parameters' do
        service.generate_response(input)
        expect(client).to have_received(:chat) do |params|
          expect(params[:parameters][:response_format]).to eq({ type: 'json_object' })
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
      let(:tool_call_id) { 'call_123' }
      let(:search_query) { 'test query' }
      let(:response_content) { 'Documentation content' }
      let(:openai_response_with_tool) do
        {
          'choices' => [
            {
              'message' => {
                'tool_calls' => [
                  {
                    'id' => tool_call_id,
                    'function' => {
                      'name' => 'search_documentation',
                      'arguments' => { 'search_query' => search_query }.to_json
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
          .and_return(openai_response_with_tool, openai_response)
        allow(captain_assistant.responses).to receive(:approved).and_return(captain_assistant.responses)
        allow(captain_assistant.responses).to receive(:search).with(search_query)
                                                              .and_return([
                                                                            instance_double(Captain::AssistantResponse,
                                                                                            question: 'Test Q?',
                                                                                            answer: 'Test A',
                                                                                            documentable: nil)
                                                                          ])
      end

      it 'processes tool calls and fetches documentation' do
        response = service.generate_response(input)
        expect(client).to have_received(:chat).at_least(:once)
        expect(response).to eq({
                                 'reasoning' => 'This is a helpful response',
                                 'response' => 'I can assist you with your questions.'
                               })
      end

      it 'appends tool calls and responses to messages' do
        service.generate_response(input)
        expect(client).to have_received(:chat).at_least(:once) do |params|
          messages = params[:parameters][:messages]
          assistant_message = messages.find { |m| m[:role] == 'assistant' }
          expect(assistant_message).to include(
            tool_calls: array_including(
              hash_including(
                'id' => tool_call_id,
                'function' => hash_including(
                  'name' => 'search_documentation',
                  'arguments' => { 'search_query' => search_query }.to_json
                )
              )
            )
          )
        end
      end

      context 'with external link' do
        before do
          allow(captain_assistant.responses).to receive(:search).with(search_query)
                                                                .and_return([
                                                                              instance_double(Captain::AssistantResponse,
                                                                                              question: 'Test Q?',
                                                                                              answer: 'Test A',
                                                                                              documentable: instance_double(Captain::Document,
                                                                                                                            external_link: 'https://example.com'))
                                                                            ])
        end

        it 'includes source in formatted response' do
          service.generate_response(input)
          expect(client).to have_received(:chat).at_least(:once) do |params|
            messages = params[:parameters][:messages]
            tool_response = messages.find { |m| m[:role] == 'tool' }
            expect(tool_response[:content]).to include('Source: https://example.com')
          end
        end
      end
    end
  end

  describe '#chat_parameters' do
    before do
      allow(client).to receive(:chat).and_return({
                                                   'choices' => [
                                                     {
                                                       'message' => {
                                                         'content' => { reasoning: '', response: '' }.to_json
                                                       }
                                                     }
                                                   ]
                                                 })
    end

    it 'includes correct model and response format' do
      service.generate_response(input)
      expect(client).to have_received(:chat).at_least(:once) do |params|
        parameters = params[:parameters]
        expect(parameters[:model]).to eq('gpt-4o-mini')
        expect(parameters[:response_format]).to eq({ type: 'json_object' })
      end
    end
  end
end
