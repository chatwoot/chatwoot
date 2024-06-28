require 'rails_helper'

RSpec.describe Enterprise::MessageTemplates::ResponseBotService, type: :service do
  let!(:conversation) { create(:conversation, status: :pending) }
  let(:service) { described_class.new(conversation: conversation) }
  let(:chat_gpt_double) { instance_double(ChatGpt) }
  let(:response_source) { create(:response_source, account: conversation.account) }
  let(:response_object) { instance_double(Response, id: 1, question: 'Q1', answer: 'A1') }

  before do
    skip_unless_response_bot_enabled_test_environment
    stub_request(:post, 'https://api.openai.com/v1/embeddings').to_return(status: 200, body: {}.to_json,
                                                                          headers: { Content_Type: 'application/json' })
    create(:message, message_type: :incoming, conversation: conversation, content: 'Hi')
    create(:message, message_type: :outgoing, conversation: conversation, content: 'Hello')
    4.times { create(:response, response_source: response_source) }
    allow(ChatGpt).to receive(:new).and_return(chat_gpt_double)
    allow(chat_gpt_double).to receive(:generate_response).and_return({ 'response' => 'some_response', 'context_ids' => Response.all.map(&:id) })
    allow(conversation.inbox).to receive(:get_responses).with('Hi').and_return([response_object])
  end

  describe '#perform' do
    context 'when successful' do
      it 'creates an outgoing message along with article references' do
        expect do
          service.perform
        end.to change { conversation.messages.where(message_type: :outgoing).count }.by(1)

        last_message = conversation.messages.last
        expect(last_message.content).to include('some_response')
        expect(last_message.content).to include(Response.first.question)
        expect(last_message.content).to include('**Sources**')
      end

      it 'hands off the conversation if the response is handoff' do
        allow(chat_gpt_double).to receive(:generate_response).and_return({ 'response' => 'conversation_handoff' })
        expect(conversation).to receive(:bot_handoff!).and_call_original

        expect do
          service.perform
        end.to change { conversation.messages.where(message_type: :outgoing).count }.by(1)

        last_message = conversation.messages.last
        expect(last_message.content).to eq('Transferring to another agent for further assistance.')
        expect(conversation.status).to eq('open')
      end
    end

    context 'when context_ids are not present' do
      it 'creates an outgoing message without article references' do
        allow(chat_gpt_double).to receive(:generate_response).and_return({ 'response' => 'some_response' })

        expect do
          service.perform
        end.to change { conversation.messages.where(message_type: :outgoing).count }.by(1)

        last_message = conversation.messages.last
        expect(last_message.content).to include('some_response')
        expect(last_message.content).not_to include('**Sources**')
      end
    end

    context 'when response doesnt have response document' do
      it 'creates an outgoing message without article references' do
        response = create(:response, response_source: response_source, response_document: nil)
        allow(chat_gpt_double).to receive(:generate_response).and_return({ 'response' => 'some_response', 'context_ids' => [response.id] })

        expect do
          service.perform
        end.to change { conversation.messages.where(message_type: :outgoing).count }.by(1)

        last_message = conversation.messages.last
        expect(last_message.content).to include('some_response')
        expect(last_message.content).not_to include('**Sources**')
      end
    end

    context 'when JSON::ParserError is raised' do
      it 'creates a handoff message' do
        allow(chat_gpt_double).to receive(:generate_response).and_raise(JSON::ParserError)
        expect(conversation).to receive(:bot_handoff!).and_call_original

        expect do
          service.perform
        end.to change { conversation.messages.where(message_type: :outgoing).count }.by(1)

        expect(conversation.messages.last.content).to eq('Transferring to another agent for further assistance.')
        expect(conversation.status).to eq('open')
      end
    end

    context 'when StandardError is raised' do
      it 'captures the exception' do
        allow(chat_gpt_double).to receive(:generate_response).and_raise(StandardError)
        expect(conversation).to receive(:bot_handoff!).and_call_original

        expect(ChatwootExceptionTracker).to receive(:new).and_call_original

        expect do
          service.perform
        end.to change { conversation.messages.where(message_type: :outgoing).count }.by(1)

        expect(conversation.messages.last.content).to eq('Transferring to another agent for further assistance.')
        expect(conversation.status).to eq('open')
      end
    end
  end
end
