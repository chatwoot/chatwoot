require 'rails_helper'

describe Integrations::Csml::ProcessorService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent_bot) { create(:agent_bot, :skip_validate, bot_type: 'csml', account: account) }
  let(:agent_bot_inbox) { create(:agent_bot_inbox, agent_bot: agent_bot, inbox: inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, status: :pending) }
  let(:message) { create(:message, account: account, conversation: conversation) }
  let(:event_name) { 'message.created' }
  let(:event_data) { { message: message } }

  describe '#perform' do
    let(:csml_client) { double }
    let(:processor) { described_class.new(event_name: event_name, agent_bot: agent_bot, event_data: event_data) }

    before do
      allow(CsmlEngine).to receive(:new).and_return(csml_client)
    end

    context 'when a conversation is completed from CSML' do
      it 'open the conversation and handsoff it to an agent' do
        csml_response = ActiveSupport::HashWithIndifferentAccess.new(conversation_end: true)
        allow(csml_client).to receive(:run).and_return(csml_response)

        processor.perform
        expect(conversation.reload.status).to eql('open')
      end
    end

    context 'when a new message is returned from CSML' do
      it 'creates a text message' do
        csml_response = ActiveSupport::HashWithIndifferentAccess.new(
          messages: [
            { payload: { content_type: 'text', content: { text: 'hello payload' } } }
          ]
        )
        allow(csml_client).to receive(:run).and_return(csml_response)
        processor.perform
        expect(conversation.messages.last.content).to eql('hello payload')
      end

      it 'creates a question message' do
        csml_response = ActiveSupport::HashWithIndifferentAccess.new(
          messages: [{
            payload: {
              content_type: 'question',
              content: { title: 'Question Payload', buttons: [{ content: { title: 'Q1', payload: 'q1' } }] }
            }
          }]
        )
        allow(csml_client).to receive(:run).and_return(csml_response)
        processor.perform
        expect(conversation.messages.last.content).to eql('Question Payload')
        expect(conversation.messages.last.content_type).to eql('input_select')
        expect(conversation.messages.last.content_attributes).to eql({ items: [{ title: 'Q1', value: 'q1' }] }.with_indifferent_access)
      end
    end

    context 'when conversation status is not pending' do
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

    context 'when message type is template (not outgoing or incoming)' do
      let(:message) { create(:message, account: account, conversation: conversation, message_type: :template) }

      it 'returns nil' do
        expect(processor.perform).to be(nil)
      end
    end

    context 'when message updated' do
      let(:event_name) { 'message.updated' }

      context 'when content_type is input_select' do
        let(:message) do
          create(:message, account: account, conversation: conversation, private: true,
                           submitted_values: [{ 'title' => 'Support', 'value' => 'selected_gas' }])
        end

        it 'returns submitted value for message content' do
          expect(processor.send(:message_content, message)).to eql('selected_gas')
        end
      end

      context 'when content_type is not input_select' do
        let(:message) { create(:message, account: account, conversation: conversation, message_type: :outgoing, content_type: :text) }
        let(:event_name) { 'message.updated' }

        it 'returns nil' do
          expect(processor.perform).to be(nil)
        end
      end
    end
  end
end
