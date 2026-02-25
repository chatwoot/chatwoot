require 'rails_helper'

describe Sms::DeliveryStatusService do
  describe '#perform' do
    let!(:account) { create(:account) }
    let!(:sms_channel) { create(:channel_sms) }
    let!(:contact) { create(:contact, account: account, phone_number: '+12345') }
    let(:contact_inbox) { create(:contact_inbox, source_id: '+12345', contact: contact, inbox: sms_channel.inbox) }
    let!(:conversation) { create(:conversation, contact: contact, inbox: sms_channel.inbox, contact_inbox: contact_inbox) }

    describe '#perform' do
      context 'when message delivery status is fired' do
        before do
          create(:message, account: account, inbox: sms_channel.inbox, conversation: conversation, status: :sent,
                           source_id: 'SMd560ac79e4a4d36b3ce59f1f50471986')
        end

        it 'updates the message if the message status is delivered' do
          params = {
            time: '2022-02-02T23:14:05.309Z',
            type: 'message-delivered',
            to: sms_channel.phone_number,
            description: 'ok',
            message: {
              'id': conversation.messages.last.source_id
            }
          }

          described_class.new(params: params, inbox: sms_channel.inbox).perform
          expect(conversation.reload.messages.last.status).to eq('delivered')
        end

        it 'updates the message if the message status is failed' do
          params = {
            time: '2022-02-02T23:14:05.309Z',
            type: 'message-failed',
            to: sms_channel.phone_number,
            description: 'Undeliverable',
            errorCode: 995,
            message: {
              'id': conversation.messages.last.source_id
            }
          }

          described_class.new(params: params, inbox: sms_channel.inbox).perform
          expect(conversation.reload.messages.last.status).to eq('failed')

          expect(conversation.reload.messages.last.external_error).to eq('995 - Undeliverable')
        end

        it 'does not update the message if the status is not a support status' do
          params = {
            time: '2022-02-02T23:14:05.309Z',
            type: 'queued',
            to: sms_channel.phone_number,
            description: 'ok',
            message: {
              'id': conversation.messages.last.source_id
            }
          }

          described_class.new(params: params, inbox: sms_channel.inbox).perform
          expect(conversation.reload.messages.last.status).to eq('sent')
        end

        it 'does not update the message if the message is not present' do
          params = {
            time: '2022-02-02T23:14:05.309Z',
            type: 'message-delivered',
            to: sms_channel.phone_number,
            description: 'ok',
            message: {
              'id': '123'
            }
          }

          described_class.new(params: params, inbox: sms_channel.inbox).perform
          expect(conversation.reload.messages.last.status).to eq('sent')
        end
      end
    end
  end
end
