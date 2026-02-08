require 'rails_helper'

describe Twilio::IncomingMessageService do
  let!(:account) { create(:account) }
  let!(:twilio_channel) do
    create(:channel_twilio_sms, account: account, account_sid: 'ACxxx',
                                inbox: create(:inbox, account: account, greeting_enabled: false))
  end
  let!(:contact) { create(:contact, account: account, phone_number: '+12345') }
  let(:contact_inbox) { create(:contact_inbox, source_id: '+12345', contact: contact, inbox: twilio_channel.inbox) }
  let!(:conversation) { create(:conversation, contact: contact, inbox: twilio_channel.inbox, contact_inbox: contact_inbox) }

  describe '#perform' do
    it 'creates a new message in existing conversation' do
      params = {
        SmsSid: 'SMxx',
        From: '+12345',
        AccountSid: 'ACxxx',
        MessagingServiceSid: twilio_channel.messaging_service_sid,
        Body: 'testing3'
      }

      described_class.new(params: params).perform
      expect(conversation.reload.messages.last.content).to eq('testing3')
    end

    it 'removes null bytes' do
      params = {
        SmsSid: 'SMxx',
        From: '+12345',
        AccountSid: 'ACxxx',
        MessagingServiceSid: twilio_channel.messaging_service_sid,
        Body: "remove\u0000 null bytes\u0000"
      }

      described_class.new(params: params).perform
      expect(conversation.reload.messages.last.content).to eq('remove null bytes')
    end

    it 'wont throw error when the body is empty' do
      params = {
        SmsSid: 'SMxx',
        From: '+12345',
        AccountSid: 'ACxxx',
        MessagingServiceSid: twilio_channel.messaging_service_sid
      }

      described_class.new(params: params).perform
      expect(conversation.reload.messages.last.content).to be_nil
    end

    it 'creates a new conversation when payload is from different number' do
      params = {
        SmsSid: 'SMxx',
        From: '+123456',
        AccountSid: 'ACxxx',
        MessagingServiceSid: twilio_channel.messaging_service_sid,
        Body: 'new conversation'
      }

      described_class.new(params: params).perform
      expect(twilio_channel.inbox.conversations.count).to eq(2)
    end

    # Since we support the case with phone number as well. the previous case is with accoud_sid and messaging_service_sid
    context 'with a phone number' do
      let!(:twilio_channel) do
        create(:channel_twilio_sms, :with_phone_number, account: account, account_sid: 'ACxxx',
                                                        inbox: create(:inbox, account: account, greeting_enabled: false))
      end

      it 'creates a new message in existing conversation' do
        params = {
          SmsSid: 'SMxx',
          From: '+12345',
          AccountSid: 'ACxxx',
          To: twilio_channel.phone_number,
          Body: 'testing3'
        }

        described_class.new(params: params).perform
        expect(conversation.reload.messages.last.content).to eq('testing3')
      end

      it 'creates a new conversation when payload is from different number' do
        params = {
          SmsSid: 'SMxx',
          From: '+123456',
          AccountSid: 'ACxxx',
          To: twilio_channel.phone_number,
          Body: 'new conversation'
        }

        described_class.new(params: params).perform
        expect(twilio_channel.inbox.conversations.count).to eq(2)
      end

      it 'reopen last conversation if last conversation is resolved and lock to single conversation is enabled' do
        params = {
          SmsSid: 'SMxx',
          From: '+12345',
          AccountSid: 'ACxxx',
          To: twilio_channel.phone_number,
          Body: 'testing3'
        }

        twilio_channel.inbox.update(lock_to_single_conversation: true)
        conversation.update(status: 'resolved')
        described_class.new(params: params).perform
        # message appended to the last conversation
        expect(conversation.reload.messages.last.content).to eq('testing3')
        expect(conversation.reload.status).to eq('open')
      end

      it 'creates a new conversation if last conversation is resolved and lock to single conversation is disabled' do
        params = {
          SmsSid: 'SMxx',
          From: '+12345',
          AccountSid: 'ACxxx',
          To: twilio_channel.phone_number,
          Body: 'testing3'
        }

        twilio_channel.inbox.update(lock_to_single_conversation: false)
        conversation.update(status: 'resolved')
        described_class.new(params: params).perform
        expect(twilio_channel.inbox.conversations.count).to eq(2)
        expect(twilio_channel.inbox.conversations.last.messages.last.content).to eq('testing3')
      end

      it 'will not create a new conversation if last conversation is not resolved and lock to single conversation is disabled' do
        params = {
          SmsSid: 'SMxx',
          From: '+12345',
          AccountSid: 'ACxxx',
          To: twilio_channel.phone_number,
          Body: 'testing3'
        }

        twilio_channel.inbox.update(lock_to_single_conversation: false)
        conversation.update(status: Conversation.statuses.except('resolved').keys.sample)
        described_class.new(params: params).perform
        expect(twilio_channel.inbox.conversations.count).to eq(1)
        expect(twilio_channel.inbox.conversations.last.messages.last.content).to eq('testing3')
      end
    end

    context 'with multiple channels configured' do
      before do
        2.times.each do
          create(:channel_twilio_sms, :with_phone_number, account: account, account_sid: 'ACxxx', messaging_service_sid: nil,
                                                          inbox: create(:inbox, account: account, greeting_enabled: false))
        end
      end

      it 'creates a new conversation in appropriate channel' do
        twilio_sms_channel = create(:channel_twilio_sms, :with_phone_number, account: account, account_sid: 'ACxxx',
                                                                             inbox: create(:inbox, account: account, greeting_enabled: false))

        params = {
          SmsSid: 'SMxx',
          From: '+123456',
          AccountSid: 'ACxxx',
          To: twilio_sms_channel.phone_number,
          Body: 'new conversation'
        }

        described_class.new(params: params).perform
        expect(twilio_sms_channel.inbox.conversations.count).to eq(1)
      end
    end

    context 'when a message with an attachment is received' do
      before do
        stub_request(:get, 'https://chatwoot-assets.local/sample.png')
          .to_return(status: 200, body: 'image data', headers: { 'Content-Type' => 'image/png' })
      end

      let(:params_with_attachment) do
        {
          SmsSid: 'SMxx',
          From: '+12345',
          AccountSid: 'ACxxx',
          MessagingServiceSid: twilio_channel.messaging_service_sid,
          Body: 'testing3',
          NumMedia: '1',
          MediaContentType0: 'image/jpeg',
          MediaUrl0: 'https://chatwoot-assets.local/sample.png'
        }
      end

      it 'creates a new message with media in existing conversation' do
        described_class.new(params: params_with_attachment).perform
        expect(conversation.reload.messages.last.content).to eq('testing3')
        expect(conversation.reload.messages.last.attachments.count).to eq(1)
        expect(conversation.reload.messages.last.attachments.first.file_type).to eq('image')
      end
    end

    context 'when there is an error downloading the attachment' do
      before do
        stub_request(:get, 'https://chatwoot-assets.local/sample.png')
          .to_raise(Down::Error.new('Download error'))

        stub_request(:get, 'https://chatwoot-assets.local/sample.png')
          .to_return(status: 200, body: 'image data', headers: { 'Content-Type' => 'image/png' })
      end

      let(:params_with_attachment_error) do
        {
          SmsSid: 'SMxx',
          From: '+12345',
          AccountSid: 'ACxxx',
          MessagingServiceSid: twilio_channel.messaging_service_sid,
          Body: 'testing3',
          NumMedia: '1',
          MediaContentType0: 'image/jpeg',
          MediaUrl0: 'https://chatwoot-assets.local/sample.png'
        }
      end

      it 'retries downloading the attachment without a token after an error' do
        expect do
          described_class.new(params: params_with_attachment_error).perform
        end.not_to raise_error

        expect(conversation.reload.messages.last.content).to eq('testing3')
        expect(conversation.reload.messages.last.attachments.count).to eq(1)
        expect(conversation.reload.messages.last.attachments.first.file_type).to eq('image')
      end
    end

    context 'when a message with multiple attachments is received' do
      before do
        stub_request(:get, 'https://chatwoot-assets.local/sample.png')
          .to_return(status: 200, body: 'image data 1', headers: { 'Content-Type' => 'image/png' })
        stub_request(:get, 'https://chatwoot-assets.local/sample.jpg')
          .to_return(status: 200, body: 'image data 2', headers: { 'Content-Type' => 'image/jpeg' })
      end

      let(:params_with_multiple_attachments) do
        {
          SmsSid: 'SMxx',
          From: '+12345',
          AccountSid: 'ACxxx',
          MessagingServiceSid: twilio_channel.messaging_service_sid,
          Body: 'testing multiple media',
          NumMedia: '2',
          MediaContentType0: 'image/png',
          MediaUrl0: 'https://chatwoot-assets.local/sample.png',
          MediaContentType1: 'image/jpeg',
          MediaUrl1: 'https://chatwoot-assets.local/sample.jpg'
        }
      end

      it 'creates a new message with multiple media attachments in existing conversation' do
        described_class.new(params: params_with_multiple_attachments).perform
        expect(conversation.reload.messages.last.content).to eq('testing multiple media')
        expect(conversation.reload.messages.last.attachments.count).to eq(2)
        expect(conversation.reload.messages.last.attachments.map(&:file_type)).to contain_exactly('image', 'image')
      end
    end
  end
end
