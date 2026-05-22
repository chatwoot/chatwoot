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

      it 'tracks previous content in content_attributes when message is edited' do
        message = create(:message, conversation: conversation, content: 'original message',
                                   source_id: text_update_params[:edited_message][:message_id])
        described_class.new(inbox: telegram_channel.inbox, params: text_update_params.with_indifferent_access).perform

        message.reload
        expect(message.content).to eq('updated message')
        previous_contents = message.content_attributes[:previous_contents]
        expect(previous_contents).to be_an(Array)
        expect(previous_contents.length).to eq(1)
        entry = previous_contents.first.with_indifferent_access
        expect(entry[:content]).to eq('original message')
        expect(entry[:edited_at]).to be_a(Integer)
      end

      it 'accumulates previous contents on multiple edits' do
        message = create(:message, conversation: conversation, content: 'first',
                                   source_id: text_update_params[:edited_message][:message_id])

        described_class.new(inbox: telegram_channel.inbox, params: text_update_params.with_indifferent_access).perform

        second_edit = text_update_params.deep_dup
        second_edit[:edited_message][:text] = 'second edit'
        described_class.new(inbox: telegram_channel.inbox, params: second_edit.with_indifferent_access).perform

        message.reload
        expect(message.content).to eq('second edit')
        contents = message.content_attributes[:previous_contents].map { |e| e.with_indifferent_access[:content] }
        expect(contents).to eq(['first', 'updated message'])
      end

      it 'does not track history when content is unchanged' do
        message = create(:message, conversation: conversation, content: 'updated message',
                                   source_id: text_update_params[:edited_message][:message_id])
        described_class.new(inbox: telegram_channel.inbox, params: text_update_params.with_indifferent_access).perform

        message.reload
        expect(message.content_attributes[:previous_contents]).to be_nil
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
