require 'rails_helper'

RSpec.describe Channel::Telegram do
  let(:telegram_channel) { create(:channel_telegram) }

  context 'when a valid message and empty attachments' do
    it 'send message' do
      message = create(:message, message_type: :outgoing, content: 'test',
                                 conversation: create(:conversation, inbox: telegram_channel.inbox, additional_attributes: { 'chat_id' => '123' }))

      stub_request(:post, "https://api.telegram.org/bot#{telegram_channel.bot_token}/sendMessage")
        .with(
          body: 'chat_id=123&text=test&reply_markup='
        )
        .to_return(
          status: 200,
          body: { result: { message_id: 'telegram_123' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect(telegram_channel.send_message_on_telegram(message)).to eq('telegram_123')
    end

    it 'send message with reply_markup' do
      message = create(
        :message, message_type: :outgoing, content: 'test', content_type: 'input_select',
                  content_attributes: { 'items' => [{ 'title' => 'test', 'value' => 'test' }] },
                  conversation: create(:conversation, inbox: telegram_channel.inbox, additional_attributes: { 'chat_id' => '123' })
      )

      stub_request(:post, "https://api.telegram.org/bot#{telegram_channel.bot_token}/sendMessage")
        .with(
          body: 'chat_id=123&text=test' \
                '&reply_markup=%7B%22one_time_keyboard%22%3Atrue%2C%22inline_keyboard%22%3A%5B%5B%7B%22text%22%3A%22test%22%2C%22' \
                'callback_data%22%3A%22test%22%7D%5D%5D%7D'
        )
        .to_return(
          status: 200,
          body: { result: { message_id: 'telegram_123' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

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
