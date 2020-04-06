require 'rails_helper'

describe Twilio::OutgoingMessageService do
  subject(:outgoing_message_service) { described_class.new(message: message) }

  let(:twilio_client) { instance_double(::Twilio::REST::Client) }
  let(:messages_double) { instance_double('messages') }
  let(:message_record_double) { instance_double('message_record_double') }

  let!(:account) { create(:account) }
  let!(:widget_inbox) { create(:inbox, account: account) }
  let!(:twilio_sms) { create(:channel_twilio_sms, account: account) }
  let!(:twilio_inbox) { create(:inbox, channel: twilio_sms, account: account) }
  let!(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: twilio_inbox) }
  let(:conversation) { create(:conversation, contact: contact, inbox: twilio_inbox, contact_inbox: contact_inbox) }

  before do
    allow(::Twilio::REST::Client).to receive(:new).and_return(twilio_client)
    allow(twilio_client).to receive(:messages).and_return(messages_double)
  end

  describe '#perform' do
    context 'without reply' do
      it 'if message is private' do
        create(:message, message_type: 'outgoing', private: true, inbox: twilio_inbox, account: account)
        expect(twilio_client).not_to have_received(:messages)
      end

      it 'if inbox channel is not facebook page' do
        create(:message, message_type: 'outgoing', inbox: widget_inbox, account: account)
        expect(twilio_client).not_to have_received(:messages)
      end

      it 'if message is not outgoing' do
        create(:message, message_type: 'incoming', inbox: twilio_inbox, account: account)
        expect(twilio_client).not_to have_received(:messages)
      end

      it 'if message has an source id' do
        create(:message, message_type: 'outgoing', inbox: twilio_inbox, account: account, source_id: SecureRandom.uuid)
        expect(twilio_client).not_to have_received(:messages)
      end
    end

    context 'with reply' do
      it 'if message is sent from chatwoot and is outgoing' do
        allow(messages_double).to receive(:create).and_return(message_record_double)
        allow(message_record_double).to receive(:sid).and_return('1234')

        outgoing_message = create(
          :message, message_type: 'outgoing', inbox: twilio_inbox, account: account, conversation: conversation
        )

        expect(outgoing_message.reload.source_id).to eq('1234')
      end
    end
  end
end
