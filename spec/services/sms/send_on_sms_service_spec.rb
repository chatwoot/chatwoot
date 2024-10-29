require 'rails_helper'

describe Sms::SendOnSmsService do
  describe '#perform' do
    context 'when a valid message' do
      let(:sms_request) { double }
      let!(:sms_channel) { create(:channel_sms) }
      let!(:contact_inbox) { create(:contact_inbox, inbox: sms_channel.inbox, source_id: '+123456789') }
      let!(:conversation) { create(:conversation, contact_inbox: contact_inbox, inbox: sms_channel.inbox) }

      it 'calls channel.send_message' do
        message = create(:message, message_type: :outgoing, content: 'test',
                                   conversation: conversation)
        allow(HTTParty).to receive(:post).and_return(sms_request)
        allow(sms_request).to receive(:success?).and_return(true)
        allow(sms_request).to receive(:parsed_response).and_return({ 'id' => '123456789' })
        expect(HTTParty).to receive(:post).with(
          'https://messaging.bandwidth.com/api/v2/users/1/messages',
          basic_auth: { username: '1', password: '1' },
          headers: { 'Content-Type' => 'application/json' },
          body: { 'to' => '+123456789', 'from' => sms_channel.phone_number, 'text' => 'test', 'applicationId' => '1' }.to_json
        )
        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'calls channel.send_message with attachments' do
        message = build(:message, message_type: :outgoing, content: 'test',
                                  conversation: conversation)
        attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
        attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
        attachment2 = message.attachments.new(account_id: message.account_id, file_type: :image)
        attachment2.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
        message.save!

        allow(HTTParty).to receive(:post).and_return(sms_request)
        allow(sms_request).to receive(:success?).and_return(true)
        allow(sms_request).to receive(:parsed_response).and_return({ 'id' => '123456789' })
        allow(attachment).to receive(:download_url).and_return('url1')
        allow(attachment2).to receive(:download_url).and_return('url2')
        expect(HTTParty).to receive(:post).with(
          'https://messaging.bandwidth.com/api/v2/users/1/messages',
          basic_auth: { username: '1', password: '1' },
          headers: { 'Content-Type' => 'application/json' },
          body: { 'to' => '+123456789', 'from' => sms_channel.phone_number, 'text' => 'test', 'applicationId' => '1',
                  'media' => %w[url1 url2] }.to_json
        )
        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end
    end
  end
end
