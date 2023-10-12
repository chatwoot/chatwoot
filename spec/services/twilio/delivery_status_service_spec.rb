require 'rails_helper'

describe Twilio::DeliveryStatusService do
  let!(:account) { create(:account) }
  let!(:twilio_channel) do
    create(:channel_twilio_sms, account: account, account_sid: 'ACxxx',
                                inbox: create(:inbox, account: account, greeting_enabled: false))
  end
  let!(:contact) { create(:contact, account: account, phone_number: '+12345') }
  let(:contact_inbox) { create(:contact_inbox, source_id: '+12345', contact: contact, inbox: twilio_channel.inbox) }
  let!(:conversation) { create(:conversation, contact: contact, inbox: twilio_channel.inbox, contact_inbox: contact_inbox) }

  describe '#perform' do
    context 'when message delivery status is fired' do
      before do
        create(:message, account: account, inbox: twilio_channel.inbox, conversation: conversation, status: :sent,
                         source_id: 'SMd560ac79e4a4d36b3ce59f1f50471986')
      end

      it 'updates the message if the status is delivered' do
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

      it 'updates the message if the status is read' do
        params = {
          SmsSid: 'SMxx',
          From: '+12345',
          AccountSid: 'ACxxx',
          MessagingServiceSid: twilio_channel.messaging_service_sid,
          MessageSid: conversation.messages.last.source_id,
          MessageStatus: 'read'
        }

        described_class.new(params: params).perform
        expect(conversation.reload.messages.last.status).to eq('read')
      end

      it 'does not update the message if the status is not a support status' do
        params = {
          SmsSid: 'SMxx',
          From: '+12345',
          AccountSid: 'ACxxx',
          MessagingServiceSid: twilio_channel.messaging_service_sid,
          MessageSid: conversation.messages.last.source_id,
          MessageStatus: 'queued'
        }

        described_class.new(params: params).perform
        expect(conversation.reload.messages.last.status).to eq('sent')
      end

      it 'updates message status to failed if message status is undelivered' do
        params = {
          SmsSid: 'SMxx',
          From: '+12345',
          AccountSid: 'ACxxx',
          MessagingServiceSid: twilio_channel.messaging_service_sid,
          MessageSid: conversation.messages.last.source_id,
          MessageStatus: 'undelivered',
          ErrorCode: '30002',
          ErrorMessage: 'Account suspended'
        }

        described_class.new(params: params).perform
        expect(conversation.reload.messages.last.status).to eq('failed')
        expect(conversation.reload.messages.last.external_error).to eq('30002 - Account suspended')
      end

      it 'updates message status to failed and updates the error message if message status is failed' do
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

      it 'updates the error message if message status is undelivered and error message is not present' do
        params = {
          SmsSid: 'SMxx',
          From: '+12345',
          AccountSid: 'ACxxx',
          MessagingServiceSid: twilio_channel.messaging_service_sid,
          MessageSid: conversation.messages.last.source_id,
          MessageStatus: 'failed',
          ErrorCode: '30008'
        }

        described_class.new(params: params).perform
        expect(conversation.reload.messages.last.status).to eq('failed')
        expect(conversation.reload.messages.last.external_error).to eq('Error code: 30008')
      end
    end
  end
end
