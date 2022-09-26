require 'rails_helper'

describe  ::Messages::Instagram::MessageBuilder do
  subject(:instagram_message_builder) { described_class }

  before do
    stub_request(:post, /graph.facebook.com/)
    stub_request(:get, 'https://www.example.com/test.jpeg')
  end

  let!(:account) { create(:account) }
  let!(:instagram_channel) { create(:channel_instagram_fb_page, account: account, instagram_id: 'chatwoot-app-user-id-1') }
  let!(:instagram_inbox) { create(:inbox, channel: instagram_channel, account: account, greeting_enabled: false) }
  let!(:dm_params) { build(:instagram_message_create_event).with_indifferent_access }
  let!(:story_mention_params) { build(:instagram_story_mention_event).with_indifferent_access }
  let(:fb_object) { double }
  let(:contact) { create(:contact, id: 'Sender-id-1', name: 'Jane Dae') }
  let(:contact_inbox) { create(:contact_inbox, contact_id: contact.id, inbox_id: instagram_inbox.id, source_id: 'Sender-id-1') }

  describe '#perform' do
    it 'creates contact and message for the facebook inbox' do
      allow(Koala::Facebook::API).to receive(:new).and_return(fb_object)
      allow(fb_object).to receive(:get_object).and_return(
        {
          name: 'Jane',
          id: 'Sender-id-1',
          account_id: instagram_inbox.account_id,
          profile_pic: 'https://chatwoot-assets.local/sample.png'
        }.with_indifferent_access
      )
      messaging = dm_params[:entry][0]['messaging'][0]
      contact_inbox
      described_class.new(messaging, instagram_inbox).perform

      instagram_inbox.reload

      expect(instagram_inbox.conversations.count).to be 1
      expect(instagram_inbox.messages.count).to be 1

      contact = instagram_channel.inbox.contacts.first
      message = instagram_channel.inbox.messages.first

      expect(contact.name).to eq('Jane Dae')
      expect(message.content).to eq('This is the first message from the customer')
    end

    it 'raises exception on deleted story' do
      allow(Koala::Facebook::API).to receive(:new).and_return(fb_object)
      allow(fb_object).to receive(:get_object).and_raise(Koala::Facebook::ClientError.new(
                                                           190,
                                                           'This Message has been deleted by the user or the business.'
                                                         ))

      messaging = story_mention_params[:entry][0][:messaging][0]
      contact_inbox
      described_class.new(messaging, instagram_inbox, outgoing_echo: false).perform

      instagram_inbox.reload

      # we would have contact created, message created but the empty message because the story mention has been deleted later
      # As they show it in instagram that this story is no longer available
      # and external attachments link would be reachable
      expect(instagram_inbox.conversations.count).to be 1
      expect(instagram_inbox.messages.count).to be 1

      contact = instagram_channel.inbox.contacts.first
      message = instagram_channel.inbox.messages.first

      expect(contact.name).to eq('Jane Dae')
      expect(message.content).to eq('This story is no longer available.')
      expect(message.attachments.count).to eq(1)
    end
  end
end
