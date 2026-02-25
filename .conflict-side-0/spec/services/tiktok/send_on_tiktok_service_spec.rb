require 'rails_helper'

RSpec.describe Tiktok::SendOnTiktokService do
  let(:tiktok_client) { instance_double(Tiktok::Client) }
  let(:status_update_service) { instance_double(Messages::StatusUpdateService, perform: true) }

  let(:channel) { create(:channel_tiktok, business_id: 'biz-123') }
  let(:inbox) { channel.inbox }
  let(:contact) { create(:contact, account: inbox.account) }
  let(:contact_inbox) { create(:contact_inbox, inbox: inbox, contact: contact, source_id: 'tt-conv-1') }
  let(:conversation) do
    create(
      :conversation,
      inbox: inbox,
      contact: contact,
      contact_inbox: contact_inbox,
      additional_attributes: { conversation_id: 'tt-conv-1' }
    )
  end

  before do
    allow(channel).to receive(:validated_access_token).and_return('valid-access-token')
    allow(Tiktok::Client).to receive(:new).and_return(tiktok_client)
    allow(Messages::StatusUpdateService).to receive(:new).and_return(status_update_service)
  end

  describe '#perform' do
    it 'sends outgoing text message and updates source_id' do
      allow(tiktok_client).to receive(:send_text_message).and_return('tt-msg-123')

      message = create(:message, message_type: :outgoing, inbox: inbox, conversation: conversation, account: inbox.account, content: 'Hello')
      message.update!(source_id: nil)

      described_class.new(message: message).perform

      expect(tiktok_client).to have_received(:send_text_message).with('tt-conv-1', 'Hello', referenced_message_id: nil)
      expect(message.reload.source_id).to eq('tt-msg-123')
      expect(Messages::StatusUpdateService).to have_received(:new).with(message, 'delivered')
    end

    it 'sends outgoing image message when a single attachment is present' do
      allow(tiktok_client).to receive(:send_media_message).and_return('tt-msg-124')

      message = build(:message, message_type: :outgoing, inbox: inbox, conversation: conversation, account: inbox.account, content: nil)
      attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
      attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
      message.save!

      described_class.new(message: message).perform

      expect(tiktok_client).to have_received(:send_media_message).with('tt-conv-1', message.attachments.first, referenced_message_id: nil)
      expect(message.reload.source_id).to eq('tt-msg-124')
    end

    it 'marks message as failed when sending multiple attachments' do
      allow(tiktok_client).to receive(:send_media_message)

      message = build(:message, message_type: :outgoing, inbox: inbox, conversation: conversation, account: inbox.account, content: nil)
      a1 = message.attachments.new(account_id: message.account_id, file_type: :image)
      a1.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
      a2 = message.attachments.new(account_id: message.account_id, file_type: :image)
      a2.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
      message.save!

      described_class.new(message: message).perform

      expect(Messages::StatusUpdateService).to have_received(:new).with(message, 'failed', kind_of(String))
      expect(tiktok_client).not_to have_received(:send_media_message)
    end
  end
end
