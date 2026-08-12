require 'rails_helper'

describe Whatsapp::IncomingMessageServiceHelpers do
  let(:test_class) do
    Class.new do
      include Whatsapp::IncomingMessageServiceHelpers

      attr_accessor :inbox, :params, :conversation, :contact, :contact_inbox, :outgoing_echo

      def initialize(inbox:, params: {}, conversation: nil, contact: nil, contact_inbox: nil, outgoing_echo: false) # rubocop:disable Metrics/ParameterLists
        @inbox = inbox
        @params = params
        @conversation = conversation
        @contact = contact
        @contact_inbox = contact_inbox
        @outgoing_echo = outgoing_echo
      end
    end
  end

  let(:account) { create(:account) }
  let(:whatsapp_channel) do
    create(:channel_whatsapp, provider: 'whatsapp_cloud', account: account, validate_provider_config: false, sync_templates: false)
  end
  let(:inbox) { whatsapp_channel.inbox }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
  let(:conversation) { create(:conversation, inbox: inbox, account: account, contact: contact, contact_inbox: contact_inbox) }

  describe '#interactive_reply_attributes' do
    context 'when message is a button reply from interactive_buttons' do
      let(:source_message) do
        create(:message, conversation: conversation, inbox: inbox, account: account,
                         message_type: :outgoing, content_type: :interactive_buttons,
                         source_id: 'wamid.source_123',
                         content_attributes: {
                           body_text: 'Pick an option',
                           buttons: [
                             { id: 'btn_1', text: 'Option A', type: 'reply' },
                             { id: 'btn_2', text: 'Option B', type: 'reply' }
                           ]
                         })
      end

      it 'extracts button reply with context' do
        service = test_class.new(inbox: inbox, conversation: conversation)
        service.instance_variable_set(:@in_reply_to_external_id, source_message.source_id)
        service.instance_variable_set(:@in_reply_to_message_id, source_message.id)

        message = {
          interactive: {
            button_reply: {
              id: 'btn_1',
              title: 'Option A'
            }
          }
        }

        result = service.interactive_reply_attributes(message)

        expect(result[:selected_reply][:id]).to eq('btn_1')
        expect(result[:selected_reply][:title]).to eq('Option A')
        expect(result[:selected_reply][:type]).to eq('button_reply')
        expect(result[:selected_reply][:source_message_id]).to eq(source_message.id)
        expect(result[:selected_reply][:button_index]).to eq(0)
      end
    end

    context 'when message is a list reply from interactive_list' do
      let(:source_message) do
        create(:message, conversation: conversation, inbox: inbox, account: account,
                         message_type: :outgoing, content_type: :interactive_list,
                         source_id: 'wamid.source_456',
                         content_attributes: {
                           body_text: 'Pick from the list',
                           action: { button_text: 'View options' },
                           sections: [
                             {
                               title: 'Section 1',
                               rows: [
                                 { id: 'row_1', title: 'Row A', description: 'First row' },
                                 { id: 'row_2', title: 'Row B', description: 'Second row' }
                               ]
                             }
                           ]
                         })
      end

      it 'extracts list reply with context' do
        service = test_class.new(inbox: inbox, conversation: conversation)
        service.instance_variable_set(:@in_reply_to_external_id, source_message.source_id)
        service.instance_variable_set(:@in_reply_to_message_id, source_message.id)

        message = {
          interactive: {
            list_reply: {
              id: 'row_2',
              title: 'Row B',
              description: 'Second row'
            }
          }
        }

        result = service.interactive_reply_attributes(message)

        expect(result[:selected_reply][:id]).to eq('row_2')
        expect(result[:selected_reply][:title]).to eq('Row B')
        expect(result[:selected_reply][:type]).to eq('list_reply')
        expect(result[:selected_reply][:source_message_id]).to eq(source_message.id)
        expect(result[:selected_reply][:section_title]).to eq('Section 1')
      end
    end

    context 'when message is a button reply from carousel' do
      let(:source_message) do
        create(:message, conversation: conversation, inbox: inbox, account: account,
                         message_type: :outgoing, content_type: :cards,
                         source_id: 'wamid.source_789',
                         content_attributes: {
                           items: [
                             {
                               title: 'Card 1',
                               description: 'First card',
                               actions: [{ type: 'reply', text: 'Select', payload: 'card_1_select' }]
                             },
                             {
                               title: 'Card 2',
                               description: 'Second card',
                               actions: [{ type: 'reply', text: 'Choose', payload: 'card_2_select' }]
                             }
                           ]
                         })
      end

      it 'extracts carousel button reply with card context' do
        service = test_class.new(inbox: inbox, conversation: conversation)
        service.instance_variable_set(:@in_reply_to_external_id, source_message.source_id)
        service.instance_variable_set(:@in_reply_to_message_id, source_message.id)

        message = {
          button: {
            payload: 'card_1_select',
            text: 'Select'
          }
        }

        result = service.interactive_reply_attributes(message)

        expect(result[:selected_reply][:id]).to eq('card_1_select')
        expect(result[:selected_reply][:title]).to eq('Select')
        expect(result[:selected_reply][:type]).to eq('button')
        expect(result[:selected_reply][:card_index]).to eq(0)
        expect(result[:selected_reply][:card_title]).to eq('Card 1')
      end
    end

    context 'when message has no interactive reply' do
      it 'returns empty hash' do
        service = test_class.new(inbox: inbox, conversation: conversation)

        message = { text: { body: 'Hello' } }

        result = service.interactive_reply_attributes(message)

        expect(result).to eq({})
      end
    end
  end

  describe '#unprocessable_message_type?' do
    it 'returns true for ephemeral messages' do
      service = test_class.new(inbox: inbox)
      expect(service.unprocessable_message_type?('ephemeral')).to be true
    end

    it 'returns true for request_welcome messages' do
      service = test_class.new(inbox: inbox)
      expect(service.unprocessable_message_type?('request_welcome')).to be true
    end

    it 'returns true for reaction messages' do
      service = test_class.new(inbox: inbox)
      expect(service.unprocessable_message_type?('reaction')).to be true
    end

    it 'returns false for text messages' do
      service = test_class.new(inbox: inbox)
      expect(service.unprocessable_message_type?('text')).to be false
    end
  end
end
