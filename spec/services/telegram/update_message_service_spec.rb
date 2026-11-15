require 'rails_helper'

describe Telegram::UpdateMessageService do
  let!(:telegram_channel) { create(:channel_telegram) }
  let(:common_message_params) do
    {
      'from': {
        'id': 123,
        'username': 'sojan'
      },
      'chat': {
        'id': 789,
        'type': 'private'
      },
      'date': Time.now.to_i,
      'edit_date': Time.now.to_i
    }
  end

  let(:text_update_params) do
    {
      'update_id': 1,
      'edited_message': common_message_params.merge(
        'message_id': 48,
        'text': 'updated message'
      )
    }
  end

  let(:caption_update_params) do
    {
      'update_id': 2,
      'edited_message': common_message_params.merge(
        'message_id': 49,
        'caption': 'updated caption'
      )
    }
  end

  describe '#perform' do
    context 'when valid update message params' do
      let(:contact_inbox) { create(:contact_inbox, inbox: telegram_channel.inbox, source_id: common_message_params[:chat][:id]) }
      let(:conversation) { create(:conversation, contact_inbox: contact_inbox) }

      it 'updates the message text when text is present' do
        message = create(:message, conversation: conversation, source_id: text_update_params[:edited_message][:message_id])
        described_class.new(inbox: telegram_channel.inbox, params: text_update_params.with_indifferent_access).perform
        expect(message.reload.content).to eq('updated message')
      end

      it 'updates the message caption when caption is present' do
        message = create(:message, conversation: conversation, source_id: caption_update_params[:edited_message][:message_id])
        described_class.new(inbox: telegram_channel.inbox, params: caption_update_params.with_indifferent_access).perform
        expect(message.reload.content).to eq('updated caption')
      end

      context 'when business message' do
        let(:text_update_params) do
          {
            'update_id': 1,
            'edited_business_message': common_message_params.merge(
              'message_id': 48,
              'text': 'updated message'
            )
          }
        end

        it 'updates the message text when text is present' do
          message = create(:message, conversation: conversation, source_id: text_update_params[:edited_business_message][:message_id])
          described_class.new(inbox: telegram_channel.inbox, params: text_update_params.with_indifferent_access).perform
          expect(message.reload.content).to eq('updated message')
        end
      end

      context 'when contact is blocked' do
        let(:blocked_contact) { create(:contact, account: telegram_channel.account, blocked: true) }
        let(:contact_inbox) { create(:contact_inbox, contact: blocked_contact, inbox: telegram_channel.inbox, source_id: common_message_params[:chat][:id]) }
        let(:conversation) { create(:conversation, contact_inbox: contact_inbox) }

        it 'does not update incoming message from blocked contact' do
          message = create(:message, conversation: conversation, source_id: text_update_params[:edited_message][:message_id], content: 'original message')
          described_class.new(inbox: telegram_channel.inbox, params: text_update_params.with_indifferent_access).perform
          expect(message.reload.content).to eq('original message')
        end

        it 'allows outgoing business message edits' do
          outgoing_business_params = {
            'update_id': 1,
            'edited_business_message': common_message_params.merge(
              'from': { 'id': 999 },
              'chat': { 'id': 789 },
              'message_id': 48,
              'text': 'updated business message'
            )
          }
          message = create(:message, conversation: conversation, source_id: 48, content: 'original business message')
          described_class.new(inbox: telegram_channel.inbox, params: outgoing_business_params.with_indifferent_access).perform
          expect(message.reload.content).to eq('updated business message')
        end
      end
    end

    context 'when invalid update message params' do
      it 'will not raise errors' do
        expect do
          described_class.new(inbox: telegram_channel.inbox, params: {}).perform
        end.not_to raise_error
      end
    end
  end
end
