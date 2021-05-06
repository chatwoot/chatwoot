require 'rails_helper'

describe Integrations::Dialogflow::ProcessorService do
  let(:account) { create(:account) }
  let(:hook) { create(:integrations_hook, app_id: 'dialogflow', account: account) }
  let(:conversation) { create(:conversation, account: account, status: :bot) }
  let(:message) { create(:message, account: account, conversation: conversation) }
  let(:event_name) { 'message.created' }
  let(:event_data) { { message: message } }

  describe '#perform' do
    let(:dialogflow_service) { double }
    let(:dialogflow_response) do
      ActiveSupport::HashWithIndifferentAccess.new(
        fulfillment_text: 'hello'
      )
    end

    let(:processor) { described_class.new(event_name: event_name, hook: hook, event_data: event_data) }

    before do
      allow(dialogflow_service).to receive(:query_result).and_return(dialogflow_response)
      allow(processor).to receive(:get_dialogflow_response).and_return(dialogflow_service)
    end

    context 'when valid message and dialogflow returns fullfillment text' do
      it 'creates the response message' do
        expect(processor.perform.content).to eql('hello')
      end
    end

    context 'when dialogflow returns fullfillment text to be empty' do
      let(:dialogflow_response) do
        ActiveSupport::HashWithIndifferentAccess.new(
          fulfillment_messages: [{ payload: { content: 'hello payload' } }]
        )
      end

      it 'creates the response message based on fulfillment messages' do
        expect(processor.perform.content).to eql('hello payload')
      end
    end

    context 'when dialogflow returns action' do
      let(:dialogflow_response) do
        ActiveSupport::HashWithIndifferentAccess.new(
          fulfillment_messages: [{ payload: { action: 'handoff' } }]
        )
      end

      it 'handsoff the conversation to agent' do
        processor.perform
        expect(conversation.status).to eql('open')
      end
    end

    context 'when conversation is not bot' do
      let(:conversation) { create(:conversation, account: account, status: :open) }

      it 'returns nil' do
        expect(processor.perform).to be(nil)
      end
    end

    context 'when message is private' do
      let(:message) { create(:message, account: account, conversation: conversation, private: true) }

      it 'returns nil' do
        expect(processor.perform).to be(nil)
      end
    end
  end
end
