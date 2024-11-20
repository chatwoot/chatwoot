require 'rails_helper'
require 'webhooks/twitter'

describe Webhooks::InstagramEventsJob do
  subject(:instagram_webhook) { described_class }

  before do
    stub_request(:post, /graph.facebook.com/)
    stub_request(:get, 'https://www.example.com/test.jpeg')
      .to_return(status: 200, body: '', headers: {})
  end

  let!(:account) { create(:account) }
  let(:return_object) do
    { name: 'Jane',
      id: 'Sender-id-1',
      account_id: instagram_inbox.account_id,
      profile_pic: 'https://chatwoot-assets.local/sample.png',
      username: 'some_user_name' }
  end
  let!(:instagram_channel) { create(:channel_instagram_fb_page, account: account, instagram_id: 'chatwoot-app-user-id-1') }
  let!(:instagram_inbox) { create(:inbox, channel: instagram_channel, account: account, greeting_enabled: false) }
  let!(:dm_params) { build(:instagram_message_create_event).with_indifferent_access }
  let!(:standby_params) { build(:instagram_message_standby_event).with_indifferent_access }
  let!(:test_params) { build(:instagram_test_text_event).with_indifferent_access }
  let!(:unsend_event) { build(:instagram_message_unsend_event).with_indifferent_access }
  let!(:attachment_params) { build(:instagram_message_attachment_event).with_indifferent_access }
  let!(:story_mention_params) { build(:instagram_story_mention_event).with_indifferent_access }
  let!(:story_mention_echo_params) { build(:instagram_story_mention_event_with_echo).with_indifferent_access }
  let!(:messaging_seen_event) { build(:messaging_seen_event).with_indifferent_access }
  let!(:unsupported_message_event) { build(:instagram_message_unsupported_event).with_indifferent_access }
  let(:fb_object) { double }

  describe '#perform' do
    context 'with direct_message params' do
      it 'creates incoming message in the instagram inbox' do
        allow(Koala::Facebook::API).to receive(:new).and_return(fb_object)
        allow(fb_object).to receive(:get_object).and_return(
          return_object.with_indifferent_access
        )
        instagram_webhook.perform_now(dm_params[:entry])

        instagram_inbox.reload

        expect(instagram_inbox.contacts.count).to be 1
        expect(instagram_inbox.contacts.last.additional_attributes['social_instagram_user_name']).to eq 'some_user_name'
        expect(instagram_inbox.conversations.count).to be 1
        expect(instagram_inbox.messages.count).to be 1
        expect(instagram_inbox.messages.last.content_attributes['is_unsupported']).to be_nil
      end

      it 'creates standby message in the instagram inbox' do
        allow(Koala::Facebook::API).to receive(:new).and_return(fb_object)
        allow(fb_object).to receive(:get_object).and_return(
          return_object.with_indifferent_access
        )
        instagram_webhook.perform_now(standby_params[:entry])

        instagram_inbox.reload

        expect(instagram_inbox.contacts.count).to be 1
        expect(instagram_inbox.contacts.last.additional_attributes['social_instagram_user_name']).to eq 'some_user_name'
        expect(instagram_inbox.conversations.count).to be 1
        expect(instagram_inbox.messages.count).to be 1

        message = instagram_inbox.messages.last
        expect(message.content).to eq('This is the first standby message from the customer, after 24 hours.')
      end

      it 'creates test text message in the instagram inbox' do
        allow(Koala::Facebook::API).to receive(:new).and_return(fb_object)
        allow(fb_object).to receive(:get_object).and_return(
          return_object.with_indifferent_access
        )
        instagram_webhook.perform_now(test_params[:entry])

        instagram_inbox.reload
        expect(instagram_inbox.messages.count).to be 1
        expect(instagram_inbox.messages.last.content).to eq('random_text')
        expect(instagram_inbox.messages.last.source_id).to eq('random_mid')
      end

      it 'handle instagram unsend message event' do
        message = create(:message, inbox_id: instagram_inbox.id, source_id: 'message-id-to-delete')
        allow(Koala::Facebook::API).to receive(:new).and_return(fb_object)
        allow(fb_object).to receive(:get_object).and_return(
          {
            name: 'Jane',
            id: 'Sender-id-1',
            account_id: instagram_inbox.account_id,
            profile_pic: 'https://chatwoot-assets.local/sample.png'
          }.with_indifferent_access
        )
        message.attachments.new(file_type: :image, external_url: 'https://www.example.com/test.jpeg')

        expect(instagram_inbox.messages.count).to be 1

        instagram_webhook.perform_now(unsend_event[:entry])

        expect(instagram_inbox.messages.last.content).to eq 'This message was deleted'
        expect(instagram_inbox.messages.last.deleted).to be true
        expect(instagram_inbox.messages.last.attachments.count).to be 0
        expect(instagram_inbox.messages.last.reload.deleted).to be true
      end

      it 'creates incoming message with attachments in the instagram inbox' do
        allow(Koala::Facebook::API).to receive(:new).and_return(fb_object)
        allow(fb_object).to receive(:get_object).and_return(
          return_object.with_indifferent_access
        )
        instagram_webhook.perform_now(attachment_params[:entry])

        instagram_inbox.reload

        expect(instagram_inbox.contacts.count).to be 1
        expect(instagram_inbox.messages.count).to be 1
        expect(instagram_inbox.messages.last.attachments.count).to be 1
      end

      it 'creates incoming message with attachments in the instagram inbox for story mention' do
        allow(Koala::Facebook::API).to receive(:new).and_return(fb_object)
        allow(fb_object).to receive(:get_object).and_return(
          return_object.with_indifferent_access,
          { story:
            {
              mention: {
                link: 'https://www.example.com/test.jpeg',
                id: '17920786367196703'
              }
            },
            from: {
              username: 'Sender-id-1', id: 'Sender-id-1'
            },
            id: 'instagram-message-id-1234' }.with_indifferent_access
        )

        instagram_webhook.perform_now(story_mention_params[:entry])

        instagram_inbox.reload

        expect(instagram_inbox.messages.count).to be 1
        expect(instagram_inbox.messages.last.attachments.count).to be 1

        attachment = instagram_inbox.messages.last.attachments.last
        expect(attachment.push_event_data[:data_url]).to eq(attachment.external_url)
      end

      it 'creates does not create contact or messages' do
        allow(Koala::Facebook::API).to receive(:new).and_return(fb_object)
        allow(fb_object).to receive(:get_object).and_raise(Koala::Facebook::ClientError)

        instagram_webhook.perform_now(story_mention_echo_params[:entry])

        instagram_inbox.reload

        expect(instagram_inbox.contacts.count).to be 0
        expect(instagram_inbox.contact_inboxes.count).to be 0
        expect(instagram_inbox.messages.count).to be 0
      end

      it 'handle messaging_seen callback' do
        expect(Instagram::ReadStatusService).to receive(:new).with(params: messaging_seen_event[:entry][0][:messaging][0]).and_call_original
        instagram_webhook.perform_now(messaging_seen_event[:entry])
      end

      it 'handles unsupported message' do
        allow(Koala::Facebook::API).to receive(:new).and_return(fb_object)
        allow(fb_object).to receive(:get_object).and_return(
          return_object.with_indifferent_access
        )

        instagram_webhook.perform_now(unsupported_message_event[:entry])
        instagram_inbox.reload

        expect(instagram_inbox.contacts.count).to be 1
        expect(instagram_inbox.contacts.last.additional_attributes['social_instagram_user_name']).to eq 'some_user_name'
        expect(instagram_inbox.conversations.count).to be 1
        expect(instagram_inbox.messages.count).to be 1
        expect(instagram_inbox.messages.last.content_attributes['is_unsupported']).to be true
      end
    end
  end
end
