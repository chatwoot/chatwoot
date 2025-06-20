require 'rails_helper'

describe Messages::Facebook::FeedActivityMessageBuilder do
  subject(:message_builder) { described_class.new(response, conversation, facebook_channel.inbox).perform }

  before do
    stub_request(:post, /graph.facebook.com/)
  end

  let!(:facebook_channel) { create(:channel_facebook_page) }
  let(:message_object) { build(:mocked_feed_message).to_json }
  let(:response) { Integrations::Facebook::FeedMessageParser.new(message_object) }
  let(:contact) { create(:contact, name: 'Jane Dae') }
  let(:contact_inbox) { create(:contact_inbox, contact_id: contact.id, inbox_id: facebook_channel.inbox.id) }
  let(:conversation) do
    create(:conversation, account_id: facebook_channel.inbox.account.id, inbox_id: facebook_channel.inbox.id,
                          contact_id: contact.id, contact_inbox_id: contact_inbox.id,
                          status: :open)
  end
  let(:fb_object) { double }
  let(:post_content) { build(:mocked_post_content).with_indifferent_access }

  describe '#perform' do
    it 'creates a new activity message' do
      allow(Koala::Facebook::API).to receive(:new).and_return(fb_object)
      allow(fb_object).to receive(:get_object).and_return(post_content)
      message_builder
      message = facebook_channel.inbox.messages.first

      expect(message.message_type).to eq('activity')
      expect(message.content).to be_present
      expect(message.content_attributes['activity_type']).to eq('post')
      expect(message.content_attributes['post']['content']).to eq(post_content['message'])
      expect(message.content_attributes['post']['created_time']).to eq(Time.parse(post_content['created_time']).strftime('%d/%m/%y %H:%M'))
      expect(message.content_attributes['post']['attachments'].first.keys).to include('type', 'url')
    end
  end
end
