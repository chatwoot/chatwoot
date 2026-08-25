require 'rails_helper'

RSpec.describe Sms::SendOnTelnyxService do
  describe '#perform' do
    let(:channel) { create(:channel_telnyx_sms) }
    let(:contact_inbox) { create(:contact_inbox, inbox: channel.inbox, source_id: '+15555550123') }
    let(:conversation) { create(:conversation, contact_inbox: contact_inbox, inbox: channel.inbox) }
    let(:message) { create(:message, message_type: :outgoing, content: 'Hello', conversation: conversation) }

    it 'stores the Telnyx message ID on the message' do
      allow(channel).to receive(:send_message).with('+15555550123', message).and_return('telnyx-message-id')
      allow(Channel::TelnyxSms).to receive(:find).with(channel.id).and_return(channel)

      described_class.new(message: message).perform

      expect(message.reload.source_id).to eq('telnyx-message-id')
    end
  end
end
