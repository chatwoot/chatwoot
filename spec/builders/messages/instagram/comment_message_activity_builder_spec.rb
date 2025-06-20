require 'rails_helper'

describe Messages::Instagram::CommentActivityMessageBuilder do
  subject(:message_builder) { described_class.new(messaging, conversation, instagram_inbox).perform }

  before do
    stub_request(:post, /graph\.instagram\.com/)
  end

  let!(:messaging) { build(:incoming_comment_ig_message) }
  let!(:account) { create(:account) }
  let!(:instagram_channel) { create(:channel_instagram, account: account, instagram_id: 'chatwoot-app-user-id-1') }
  let!(:instagram_inbox) { create(:inbox, channel: instagram_channel, account: account, greeting_enabled: false) }
  let!(:contact) { create(:contact, id: 'Sender-id-1', name: 'Jane Dae') }
  let!(:contact_inbox) { create(:contact_inbox, contact_id: contact.id, inbox_id: instagram_inbox.id, source_id: 'Sender-id-1') }
  let(:conversation) do
    create(:conversation, account_id: account.id, inbox_id: instagram_inbox.id, contact_id: contact.id)
  end

  let!(:post_content) { build(:mocked_ig_post_content).with_indifferent_access }

  describe '#perform' do
    it 'creates an activity message' do
      allow(HTTParty).to receive(:get).and_return(post_content)
      message_builder
      message = instagram_inbox.messages.first

      expect(message.message_type).to eq('activity')
      expect(message.content).to be_present
      expect(message.content_attributes['activity_type']).to eq('post')
      expect(message.content_attributes['post']['content']).to eq(post_content['caption'])
      expect(message.content_attributes['post']['created_time']).to eq(Time.parse(post_content['timestamp']).strftime('%d/%m/%y %H:%M'))
      expect(message.content_attributes['post']['attachments'].first['type']).to eq('image')
      expect(message.content_attributes['post']['attachments'].first['url']).to eq(post_content['media_url'])
    end
  end
end
