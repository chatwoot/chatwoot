require 'rails_helper'

describe Telegram::SendOnTelegramService do
  describe '#perform' do
    let(:telegram_channel) { create(:channel_telegram) }
    let(:conversation) { create(:conversation, inbox: telegram_channel.inbox, additional_attributes: { 'chat_id' => '123' }) }
    let(:message) { create(:message, message_type: :outgoing, content: 'test', conversation: conversation) }

    context 'when a valid message' do
      it 'calls channel.send_message_on_telegram' do
        telegram_request = double
        allow(HTTParty).to receive(:post).and_return(telegram_request)
        allow(telegram_request).to receive(:success?).and_return(true)
        allow(telegram_request).to receive(:parsed_response).and_return({ 'result' => { 'message_id' => 'telegram_123' } })
        described_class.new(message: message).perform
        expect(message.source_id).to eq('telegram_123')
      end
    end

    context 'when the message creates several telegram messages' do
      before do
        allow(telegram_channel).to receive(:send_message_on_telegram).with(message).and_return([101, 102, 103])
        allow(message.inbox).to receive(:channel).and_return(telegram_channel)
      end

      it 'stores the first id as source_id and keeps every id' do
        described_class.new(message: message).perform

        expect(message.reload.source_id).to eq('101')
        expect(message.external_source_ids['telegram_message_ids']).to eq([101, 102, 103])
      end

      it 'keeps the ids from an earlier attempt when the message is sent again' do
        message.update!(external_source_ids: { 'telegram_message_ids' => [99] })

        described_class.new(message: message).perform

        expect(message.reload.external_source_ids['telegram_message_ids']).to eq([99, 101, 102, 103])
      end
    end

    context 'when nothing reaches telegram' do
      it 'does not set the source_id' do
        allow(telegram_channel).to receive(:send_message_on_telegram).with(message).and_return([])
        allow(message.inbox).to receive(:channel).and_return(telegram_channel)

        described_class.new(message: message).perform

        expect(message.reload.source_id).to be_nil
        expect(message.external_source_ids).not_to have_key('telegram_message_ids')
      end
    end
  end
end
