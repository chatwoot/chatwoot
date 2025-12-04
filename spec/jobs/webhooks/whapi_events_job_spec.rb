# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Webhooks::WhapiEventsJob, type: :job do
  let(:account) { create(:account) }
  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'whatsapp_light', account: account) }
  let(:inbox) { create(:inbox, channel: whatsapp_channel, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, inbox: inbox, contact: contact, source_id: '1234567890') }
  let(:conversation) { create(:conversation, inbox: inbox, contact: contact, contact_inbox: contact_inbox) }

  describe '#perform' do
    context 'when receiving a status event' do
      let!(:message) { create(:message, conversation: conversation, source_id: 'msg_outgoing_123', status: :sent) }
      let(:payload) do
        {
          'statuses' => [{
            'id' => 'msg_outgoing_123',
            'status' => 'delivered',
            'timestamp' => Time.current.to_i
          }]
        }.to_json
      end

      it 'updates message status to delivered' do
        described_class.new.perform(inbox.id, 'statuses', payload)
        expect(message.reload.status).to eq('delivered')
      end

      context 'when message is read' do
        let(:payload) do
          {
            'statuses' => [{
              'id' => 'msg_outgoing_123',
              'status' => 'read',
              'timestamp' => Time.current.to_i
            }]
          }.to_json
        end

        it 'updates message status to read' do
          described_class.new.perform(inbox.id, 'statuses', payload)
          expect(message.reload.status).to eq('read')
        end
      end

      context 'when message failed' do
        let(:payload) do
          {
            'statuses' => [{
              'id' => 'msg_outgoing_123',
              'status' => 'failed',
              'timestamp' => Time.current.to_i
            }]
          }.to_json
        end

        it 'updates message status to failed' do
          described_class.new.perform(inbox.id, 'statuses', payload)
          expect(message.reload.status).to eq('failed')
        end
      end
    end

    context 'when receiving multiple statuses' do
      let!(:message1) { create(:message, conversation: conversation, source_id: 'msg_1', status: :sent) }
      let!(:message2) { create(:message, conversation: conversation, source_id: 'msg_2', status: :sent) }
      let(:payload) do
        {
          'statuses' => [
            { 'id' => 'msg_1', 'status' => 'delivered', 'timestamp' => Time.current.to_i },
            { 'id' => 'msg_2', 'status' => 'read', 'timestamp' => Time.current.to_i }
          ]
        }.to_json
      end

      it 'updates all message statuses' do
        described_class.new.perform(inbox.id, 'statuses', payload)
        expect(message1.reload.status).to eq('delivered')
        expect(message2.reload.status).to eq('read')
      end
    end

    context 'when inbox does not exist' do
      it 'does not raise error' do
        expect do
          described_class.new.perform(999_999, 'messages', '{}')
        end.not_to raise_error
      end
    end

    context 'when payload is invalid JSON' do
      it 'does not crash' do
        expect do
          described_class.new.perform(inbox.id, 'messages', 'invalid json')
        end.not_to raise_error
      end
    end
  end
end
