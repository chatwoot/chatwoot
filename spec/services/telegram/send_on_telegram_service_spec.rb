require 'rails_helper'

describe Telegram::SendOnTelegramService do
  describe '#perform' do

    let(:telegram_channel) { create(:channel_telegram) }

    context 'when a valid message text' do
      it 'calls channel.send_message_on_telegram' do
        telegram_request = double
        message = create(:message, message_type: :outgoing, content: 'test',
                                   conversation: create(:conversation, inbox: telegram_channel.inbox, additional_attributes: { 'chat_id' => '123' }))
        allow(HTTParty).to receive(:post).and_return(telegram_request)
        allow(telegram_request).to receive(:success?).and_return(true)
        allow(telegram_request).to receive(:parsed_response).and_return({ 'result' => { 'message_id' => 'telegram_123' } })
        described_class.new(message: message).perform
        expect(message.source_id).to eq('telegram_123')
      end
    end

    context 'when a valid message attachment' do
      it 'calls channel.send_message_on_telegram' do
        telegram_request = double
        message = create(:message, message_type: :outgoing,
                                   conversation: create(:conversation, inbox: telegram_channel.inbox, additional_attributes: { 'chat_id' => '456' }))
        attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
        attachment.file.attach(io: File.open(Rails.root.join('spec/assets/avatar.png')), filename: 'avatar.png', content_type: 'image/png')
                                   
        allow(HTTParty).to receive(:post).and_return(telegram_request)
        allow(telegram_request).to receive(:success?).and_return(true)
        allow(telegram_request).to receive(:parsed_response).and_return({ 'result' => [{ 'message_id' => 'telegram_456' }] })
        described_class.new(message: message).perform
        expect(message.source_id).to eq('telegram_456')
      end
    end
  end
end
