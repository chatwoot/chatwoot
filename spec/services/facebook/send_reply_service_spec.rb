require 'rails_helper'

describe Facebook::SendReplyService do
  subject(:send_reply_service) { described_class.new(message: message) }

  before do
    allow(Facebook::Messenger::Subscriptions).to receive(:subscribe).and_return(true)
    allow(bot).to receive(:deliver)
  end

  let!(:account) { create(:account) }
  let(:bot) { class_double('Bot').as_stubbed_const }
  let!(:widget_inbox) { create(:inbox, account: account) }
  let!(:facebook_channel) { create(:channel_facebook_page, account: account) }
  let!(:facebook_inbox) { create(:inbox, channel: facebook_channel, account: account) }
  let!(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: facebook_inbox) }
  let(:conversation) { create(:conversation, contact: contact, inbox: facebook_inbox, contact_inbox: contact_inbox) }

  describe '#perform' do
    context 'without reply' do
      it 'if message is private' do
        create(:message, message_type: 'outgoing', private: true, inbox: facebook_inbox, account: account)
        expect(bot).not_to have_received(:deliver)
      end

      it 'if inbox channel is not facebook page' do
        create(:message, message_type: 'outgoing', inbox: widget_inbox, account: account)
        expect(bot).not_to have_received(:deliver)
      end

      it 'if message is not outgoing' do
        create(:message, message_type: 'incoming', inbox: facebook_inbox, account: account)
        expect(bot).not_to have_received(:deliver)
      end

      it 'if message has an FB ID' do
        create(:message, message_type: 'outgoing', inbox: facebook_inbox, account: account, source_id: SecureRandom.uuid)
        expect(bot).not_to have_received(:deliver)
      end
    end

    context 'with reply' do
      it 'if message is sent from chatwoot and is outgoing' do
        create(:message, message_type: :incoming, inbox: facebook_inbox, account: account, conversation: conversation)
        create(:message, message_type: 'outgoing', inbox: facebook_inbox, account: account, conversation: conversation)
        expect(bot).to have_received(:deliver)
      end

      it 'if message with attachment is sent from chatwoot and is outgoing' do
        create(:message, message_type: :incoming, inbox: facebook_inbox, account: account, conversation: conversation)
        message = build(:message, message_type: 'outgoing', inbox: facebook_inbox, account: account, conversation: conversation)
        attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
        attachment.file.attach(io: File.open(Rails.root.join('spec/assets/avatar.png')), filename: 'avatar.png', content_type: 'image/png')
        message.save!
        expect(bot).to have_received(:deliver)
      end
    end
  end
end
