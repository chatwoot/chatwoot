require 'rails_helper'

describe Instagram::ReadStatusService do
  before do
    create(:message, message_type: :incoming, inbox: instagram_inbox, account: account, conversation: conversation,
                     source_id: 'chatwoot-app-user-id-1')
  end

  let!(:account) { create(:account) }
  let!(:instagram_channel) { create(:channel_instagram_fb_page, account: account, instagram_id: 'chatwoot-app-user-id-1') }
  let!(:instagram_inbox) { create(:inbox, channel: instagram_channel, account: account, greeting_enabled: false) }
  let!(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: instagram_inbox) }
  let(:conversation) { create(:conversation, contact: contact, inbox: instagram_inbox, contact_inbox: contact_inbox) }

  describe '#perform' do
    context 'when messaging_seen callback is fired' do
      let(:message) { conversation.messages.last }

      before do
        allow(Conversations::UpdateMessageStatusJob).to receive(:perform_later)
      end

      it 'enqueues the UpdateMessageStatusJob with correct parameters if the message is found' do
        params = {
          recipient: {
            id: 'chatwoot-app-user-id-1'
          },
          read: {
            mid: message.source_id
          }
        }
        described_class.new(params: params, channel: instagram_channel).perform
        expect(Conversations::UpdateMessageStatusJob).to have_received(:perform_later).with(conversation.id, message.created_at)
      end

      it 'does not enqueue the UpdateMessageStatusJob if the message is not found' do
        params = {
          recipient: {
            id: 'chatwoot-app-user-id-1'
          },
          read: {
            mid: 'random-message-id'
          }
        }
        described_class.new(params: params, channel: instagram_channel).perform
        expect(Conversations::UpdateMessageStatusJob).not_to have_received(:perform_later)
      end
    end
  end

  context 'with Unified Login' do
    let(:instagram_channel) { create(:channel_instagram, account: account, auth_type: 'unified_login', expires_at: nil) }
    let(:instagram_inbox) { instagram_channel.inbox }
    let(:ids) { JSON.parse(Rails.root.join('spec/fixtures/instagram/unified_login_message_ids.json').read) }

    it 'marks the original send API message as read when the webhook uses its echo ID' do
      message = create(:message, account: account, inbox: instagram_inbox, conversation: conversation,
                                 message_type: :outgoing, source_id: ids.fetch('first_send'))
      allow(Conversations::UpdateMessageStatusJob).to receive(:perform_later)
      described_class.new(params: { read: { mid: ids.fetch('first_echo') } }, channel: instagram_channel).perform

      expect(Conversations::UpdateMessageStatusJob).to have_received(:perform_later).with(conversation.id, message.created_at)
    end
  end
end
