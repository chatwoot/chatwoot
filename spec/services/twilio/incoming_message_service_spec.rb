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

    context 'updates message status' do
      before do
        create(:message, account: account, inbox: twilio_channel.inbox, conversation: conversation, status: :sent,
                         source_id: 'SMd560ac79e4a4d36b3ce59f1f50471986')
      end

      it 'when message status is fired' do
        params = {
          SmsSid: 'SMxx',
          From: '+12345',
          AccountSid: 'ACxxx',
          MessagingServiceSid: twilio_channel.messaging_service_sid,
          MessageSid: conversation.messages.last.source_id,
          MessageStatus: 'delivered'
        }

        described_class.new(params: params).perform
        expect(conversation.reload.messages.last.status).to eq('delivered')
      end

      it 'updates message status to failed if message status is failed' do
        params = {
          SmsSid: 'SMxx',
          From: '+12345',
          AccountSid: 'ACxxx',
          MessagingServiceSid: twilio_channel.messaging_service_sid,
          MessageSid: conversation.messages.last.source_id,
          MessageStatus: 'failed'
        }

        described_class.new(params: params).perform
        expect(conversation.reload.messages.last.status).to eq('failed')
      end

      it 'updates message status to failed and updated the reason if message status is undelivered' do
        params = {
          SmsSid: 'SMxx',
          From: '+12345',
          AccountSid: 'ACxxx',
          MessagingServiceSid: twilio_channel.messaging_service_sid,
          MessageSid: conversation.messages.last.source_id,
          MessageStatus: 'failed',
          ErrorCode: '30008',
          ErrorMessage: 'Unknown error'
        }

        described_class.new(params: params).perform
        expect(conversation.reload.messages.last.status).to eq('failed')
        expect(conversation.reload.messages.last.external_error).to eq('30008 - Unknown error')
      end
    end
  end
end
