require 'rails_helper'

describe Telegram::SendOnTelegramService do
  describe '#perform' do
    context 'when a valid message' do
      it 'calls channel.send_message_on_telegram' do
        telegram_request = double
        telegram_channel = create(:channel_telegram)
        message = create(:message, message_type: :outgoing, content: 'test',
                                   conversation: create(:conversation, inbox: telegram_channel.inbox, additional_attributes: { 'chat_id' => '123' }))
        allow(HTTParty).to receive(:post).and_return(telegram_request)
        allow(telegram_request).to receive(:success?).and_return(true)
        allow(telegram_request).to receive(:parsed_response).and_return({ 'result' => { 'message_id' => 'telegram_123' } })
        described_class.new(message: message).perform
        expect(message.source_id).to eq('telegram_123')
      end
    end
  end
end
