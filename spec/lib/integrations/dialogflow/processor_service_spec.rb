require 'rails_helper'

describe Integrations::Dialogflow::ProcessorService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:hook) { create(:integrations_hook, :dialogflow, inbox: inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, status: :pending) }
  let(:message) { create(:message, account: account, conversation: conversation) }
  let(:event_name) { 'message.created' }
  let(:event_data) { { message: message } }
  let(:dialogflow_text_double) { double }

  describe '#perform' do
    let(:dialogflow_service) { double }
    let(:dialogflow_response) do
      ActiveSupport::HashWithIndifferentAccess.new(
        fulfillment_messages: [
          { text: dialogflow_text_double }
        ]
      )
    end

    let(:processor) { described_class.new(event_name: event_name, hook: hook, event_data: event_data) }

    before do
      allow(dialogflow_service).to receive(:query_result).and_return(dialogflow_response)
      allow(processor).to receive(:get_dialogflow_response).and_return(dialogflow_service)
      allow(dialogflow_text_double).to receive(:to_h).and_return({ text: ['hello payload'] })
    end

    context 'when valid message and dialogflow returns fullfillment text' do
      it 'creates the response message' do
        processor.perform
        expect(conversation.reload.messages.last.content).to eql('hello payload')
      end
    end

    context 'when dialogflow returns fullfillment text to be empty' do
      let(:dialogflow_response) do
        ActiveSupport::HashWithIndifferentAccess.new(
          fulfillment_messages: [{ payload: { content: 'hello payload random' } }]
        )
      end

      it 'creates the response message based on fulfillment messages' do
        processor.perform
        expect(conversation.reload.messages.last.content).to eql('hello payload random')
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

    context 'when dialogflow returns action and messages if available' do
      let(:dialogflow_response) do
        ActiveSupport::HashWithIndifferentAccess.new(
          fulfillment_messages: [{ payload: { action: 'handoff' } }, { text: dialogflow_text_double }]
        )
      end

      it 'handsoff the conversation to agent' do
        processor.perform
        expect(conversation.reload.status).to eql('open')
        expect(conversation.messages.last.content).to eql('hello payload')
      end
    end

    context 'when dialogflow returns resolve action' do
      let(:dialogflow_response) do
        ActiveSupport::HashWithIndifferentAccess.new(
          fulfillment_messages: [{ payload: { action: 'resolve' } }, { text: dialogflow_text_double }]
        )
      end

      it 'resolves the conversation without moving it to an agent' do
        processor.perform
        expect(conversation.reload.status).to eql('resolved')
        expect(conversation.messages.last.content).to eql('hello payload')
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

    context 'when message updated' do
      let(:message) do
        create(:message, account: account, conversation: conversation, private: true,
                         submitted_values: [{ 'title' => 'Support', 'value' => 'selected_gas' }])
      end
      let(:event_name) { 'message.updated' }

      it 'returns submitted value for message content' do
        expect(processor.send(:message_content, message)).to eql('selected_gas')
      end
    end
  end
end
