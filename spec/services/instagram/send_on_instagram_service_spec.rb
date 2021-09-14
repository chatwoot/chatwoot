require 'rails_helper'

describe Instagram::SendOnInstagramService do
  subject(:send_reply_service) { described_class.new(message: message) }

  before do
    create(:message, message_type: :incoming, inbox: instagram_inbox, account: account, conversation: conversation)
  end

  let!(:account) { create(:account) }
  let!(:instagram_channel) { create(:channel_instagram_fb_page, account: account, instagram_id: 'chatwoot-app-user-id-1') }
  let!(:instagram_inbox) { create(:inbox, channel: instagram_channel, account: account, greeting_enabled: false) }
  let!(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: instagram_inbox) }
  let(:conversation) { create(:conversation, contact: contact, inbox: instagram_inbox, contact_inbox: contact_inbox) }
  let(:response) { double }

  describe '#perform' do
    context 'with reply' do
      before do
        allow(Facebook::Messenger::Configuration::AppSecretProofCalculator).to receive(:call).and_return('app_secret_key', 'access_token')
        allow(HTTParty).to receive(:post).and_return(
          {
            body: { recipient: { id: contact_inbox.source_id } }
          }
        )
      end

      it 'if message is sent from chatwoot and is outgoing' do
        message = create(:message, message_type: 'outgoing', inbox: instagram_inbox, account: account, conversation: conversation)
        response = ::Instagram::SendOnInstagramService.new(message: message).perform
        expect(response).to eq({ recipient: { id: contact_inbox.source_id } })
      end

      it 'if message with attachment is sent from chatwoot and is outgoing' do
        message = build(:message, message_type: 'outgoing', inbox: instagram_inbox, account: account, conversation: conversation)
        attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
        attachment.file.attach(io: File.open(Rails.root.join('spec/assets/avatar.png')), filename: 'avatar.png', content_type: 'image/png')
        message.save!
        response = ::Instagram::SendOnInstagramService.new(message: message).perform
        expect(response).to eq({ recipient: { id: contact_inbox.source_id } })
      end
    end
  end
end
