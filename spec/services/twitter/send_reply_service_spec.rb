require 'rails_helper'

describe Twitter::SendReplyService do
  subject(:send_reply_service) { described_class.new(message: message) }

  before do
    allow($twitter).to receive(:send_direct_message).and_return(true)
  end

  let!(:account) { create(:account) }
  let!(:widget_inbox) { create(:inbox, account: account) }
  let!(:twitter_channel) { create(:channel_twitter_profile, account: account) }
  let!(:twitter_inbox) { create(:inbox, channel: twitter_channel, account: account) }
  let!(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: twitter_inbox) }
  let(:conversation) { create(:conversation, contact: contact, inbox: twitter_inbox, contact_inbox: contact_inbox) }

  describe '#perform' do
    context 'without reply' do
      it 'if message is private' do
        create(:message, message_type: 'outgoing', private: true, inbox: twitter_inbox, account: account)
        expect($twitter).not_to have_received(:send_direct_message)
      end

      it 'if inbox channel is not twitter profile' do
        create(:message, message_type: 'outgoing', inbox: widget_inbox, account: account)
        expect($twitter).not_to have_received(:send_direct_message)
      end

      it 'if message is not outgoing' do
        create(:message, message_type: 'incoming', inbox: twitter_inbox, account: account)
        expect($twitter).not_to have_received(:send_direct_message)
      end
    end

    context 'with reply' do
      it 'if message is sent from chatwoot and is outgoing' do
        create(:message, message_type: :incoming, inbox: twitter_inbox, account: account, conversation: conversation)
        create(:message, message_type: 'outgoing', inbox: twitter_inbox, account: account, conversation: conversation)
        expect($twitter).to have_received(:send_direct_message)
      end
    end
  end
end
