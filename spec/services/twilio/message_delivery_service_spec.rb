require 'rails_helper'

describe Twilio::MessageDeliveryService do
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
