require 'rails_helper'

describe Integrations::Dialogflow::ProcessorService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:hook) { create(:integrations_hook, :dialogflow, inbox: inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, status: :pending) }
  let(:message) { create(:message, account: account, conversation: conversation) }
  let(:template_message) { create(:message, account: account, conversation: conversation, message_type: :template, content: 'Bot message') }
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
      allow(processor).to receive(:get_response).and_return(dialogflow_service)
      allow(dialogflow_text_double).to receive(:to_h).and_return({ text: ['hello payload'] })
    end

    context 'when valid message and dialogflow returns fullfillment text' do
      it 'creates the response message' do
        processor.perform
        expect(conversation.reload.messages.last.content).to eql('hello payload')
      end
    end

    context 'when invalid message and dialogflow returns empty block' do
      it 'will not create the response message' do
        event_data = { message: template_message }
        processor = described_class.new(event_name: event_name, hook: hook, event_data: event_data)
        processor.perform
        expect(conversation.reload.messages.last.content).not_to eql('hello payload')
      end
    end

    context 'when dilogflow raises exception' do
      it 'tracks hook into exception tracked' do
        last_message = conversation.reload.messages.last.content
        allow(dialogflow_service).to receive(:query_result).and_raise(StandardError)
        processor.perform
        expect(conversation.reload.messages.last.content).to eql(last_message)
      end
    end

    context 'when dilogflow settings are not present' do
      it 'will get empty response' do
        last_count = conversation.reload.messages.count
        allow(processor).to receive(:get_response).and_return({})
        hook.settings = { 'project_id' => 'something_invalid', 'credentials' => {} }
        hook.save!
        processor.perform

        expect(conversation.reload.messages.count).to eql(last_count)
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
        expect(processor.perform).to be_nil
      end
    end

    context 'when message is private' do
      let(:message) { create(:message, account: account, conversation: conversation, private: true) }

      it 'returns nil' do
        expect(processor.perform).to be_nil
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

  describe '#get_response' do
    let(:google_dialogflow) { Google::Cloud::Dialogflow::V2::Sessions::Client }
    let(:session_client) { double }
    let(:session) { double }
    let(:query_input) { { text: { text: message, language_code: 'en-US' } } }
    let(:processor) { described_class.new(event_name: event_name, hook: hook, event_data: event_data) }

    before do
      hook.update(settings: { 'project_id' => 'test', 'credentials' => 'creds' }) # rubocop:disable Rails/SaveBang
      allow(google_dialogflow).to receive(:new).and_return(session_client)
      allow(session_client).to receive(:detect_intent).and_return({ session: session, query_input: query_input })
    end

    it 'returns intended response' do
      response = processor.send(:get_response, conversation.contact_inbox.source_id, message.content)
      expect(response[:query_input][:text][:text]).to eq(message)
      expect(response[:query_input][:text][:language_code]).to eq('en-US')
    end

    it 'disables the hook if permission errors are thrown' do
      allow(session_client).to receive(:detect_intent).and_raise(Google::Cloud::PermissionDeniedError)

      expect { processor.send(:get_response, conversation.contact_inbox.source_id, message.content) }
        .to change(hook, :status).from('enabled').to('disabled')
    end
  end
end
