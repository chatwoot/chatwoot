require 'rails_helper'

RSpec.describe GooglePlay::SendOnGooglePlayService do
  let(:channel) { create(:channel_google_play) }
  let(:inbox) { channel.inbox }
  let(:contact) { create(:contact, account: channel.account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox, source_id: 'REV-1') }
  let(:conversation) { create(:conversation, contact: contact, contact_inbox: contact_inbox, inbox: inbox, account: channel.account) }
  let(:message) { create(:message, message_type: :outgoing, content: 'thanks', conversation: conversation, inbox: inbox, account: channel.account) }

  describe '#perform' do
    it 'stamps the outgoing message with the source_id returned from the API' do
      allow(channel).to receive(:reply_to_review).with('REV-1', 'thanks').and_return('REV-1::reply::42')
      allow_any_instance_of(Inbox).to receive(:channel).and_return(channel)

      described_class.new(message: message).perform

      expect(message.reload.source_id).to eq('REV-1::reply::42')
      expect(message.status).to eq('sent')
    end

    it 'marks the message as failed when the API call raises' do
      allow(channel).to receive(:reply_to_review).and_raise(StandardError, 'Google Play reply failed (403)')
      allow_any_instance_of(Inbox).to receive(:channel).and_return(channel)
      allow(ChatwootExceptionTracker).to receive(:new).and_call_original

      described_class.new(message: message).perform

      expect(message.reload.status).to eq('failed')
      expect(message.external_error).to eq('Google Play reply failed (403)')
      expect(ChatwootExceptionTracker).to have_received(:new)
    end
  end
end
