require 'rails_helper'

RSpec.describe Channel::Telegram do
  let(:telegram_channel) { create(:channel_telegram) }

  context 'when a valid message and empty attachments' do
    it 'send message' do
      message = create(:message, message_type: :outgoing, content: 'test',
                                 conversation: create(:conversation, inbox: telegram_channel.inbox, additional_attributes: { 'chat_id' => '123' }))

      telegram_message_response = double

      allow(telegram_message_response).to receive(:success?).and_return(true)
      allow(telegram_message_response).to receive(:parsed_response).and_return({ 'result' => { 'message_id' => 'telegram_123' } })
      allow(telegram_channel).to receive(:message_request).and_return(telegram_message_response)
      expect(telegram_channel.send_message_on_telegram(message)).to eq('telegram_123')
    end
  end

  context 'when a empty message and valid attachments' do
    let(:message) do
      create(:message, message_type: :outgoing, content: nil,
                       conversation: create(:conversation, inbox: telegram_channel.inbox, additional_attributes: { 'chat_id' => '123' }))
    end

    it 'send image' do
      telegram_attachment_response = double
      attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
      attachment.file.attach(io: File.open(Rails.root.join('spec/assets/avatar.png')), filename: 'avatar.png', content_type: 'image/png')

      allow(telegram_attachment_response).to receive(:success?).and_return(true)
      allow(telegram_attachment_response).to receive(:parsed_response).and_return({ 'result' => [{ 'message_id' => 'telegram_456' }] })
      allow(telegram_channel).to receive(:attachments_request).and_return(telegram_attachment_response)
      expect(telegram_channel.send_message_on_telegram(message)).to eq('telegram_456')
    end

    it 'send document' do
      telegram_attachment_response = double
      attachment = message.attachments.new(account_id: message.account_id, file_type: :file)
      attachment.file.attach(io: File.open(Rails.root.join('spec/assets/attachment.pdf')), filename: 'attachment.pdf',
                             content_type: 'application/pdf')

      allow(telegram_attachment_response).to receive(:success?).and_return(true)
      allow(telegram_attachment_response).to receive(:parsed_response).and_return({ 'result' => [{ 'message_id' => 'telegram_456' }] })
      allow(telegram_channel).to receive(:attachments_request).and_return(telegram_attachment_response)
      expect(telegram_channel.send_message_on_telegram(message)).to eq('telegram_456')
    end
  end

  context 'when a valid message and valid attachment' do
    it 'send both message and attachment' do
      message = create(:message, message_type: :outgoing, content: 'test',
                                 conversation: create(:conversation, inbox: telegram_channel.inbox, additional_attributes: { 'chat_id' => '123' }))

      telegram_message_response = double
      telegram_attachment_response = double
      attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
      attachment.file.attach(io: File.open(Rails.root.join('spec/assets/avatar.png')), filename: 'avatar.png', content_type: 'image/png')

      allow(telegram_message_response).to receive(:success?).and_return(true)
      allow(telegram_message_response).to receive(:parsed_response).and_return({ 'result' => { 'message_id' => 'telegram_456' } })
      allow(telegram_attachment_response).to receive(:success?).and_return(true)
      allow(telegram_attachment_response).to receive(:parsed_response).and_return({ 'result' => [{ 'message_id' => 'telegram_789' }] })

      allow(telegram_channel).to receive(:message_request).and_return(telegram_message_response)
      allow(telegram_channel).to receive(:attachments_request).and_return(telegram_attachment_response)
      expect(telegram_channel.send_message_on_telegram(message)).to eq('telegram_789')
    end
  end
end
