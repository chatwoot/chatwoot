require 'rails_helper'

describe Telegram::UpdateMessageService do
  let!(:telegram_channel) { create(:channel_telegram) }
  let!(:update_params) do
    {
      'update_id': 2_323_484,
      'edited_message': {
        'message_id': 48,
        'from': {
          'id': 512_313_123_171_248,
          'is_bot': false,
          'first_name': 'Sojan',
          'last_name': 'Jose',
          'username': 'sojan'
        },
        'chat': {
          'id': 517_123_213_211_248,
          'first_name': 'Sojan',
          'last_name': 'Jose',
          'username': 'sojan',
          'type': 'private'
        },
        'date': 1_680_088_034,
        'edit_date': 1_680_088_056,
        'text': 'updated message'
      }
    }
  end

  describe '#perform' do
    context 'when valid update message params' do
      it 'updates the appropriate message' do
        contact_inbox = create(:contact_inbox, inbox: telegram_channel.inbox, source_id: update_params[:edited_message][:chat][:id])
        conversation = create(:conversation, contact_inbox: contact_inbox)
        message = create(:message, conversation: conversation, source_id: update_params[:edited_message][:message_id])
        described_class.new(inbox: telegram_channel.inbox, params: update_params.with_indifferent_access).perform
        expect(message.reload.content).to eq('updated message')
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
