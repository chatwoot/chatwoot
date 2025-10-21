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
end
