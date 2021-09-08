require 'rails_helper'
require 'webhooks/twitter'

describe Webhooks::Instagram do
  subject(:instagram_webhook) { described_class }

  let!(:account) { create(:account) }
  let!(:instagram_channel) { create(:channel_instagram_fb_page, account: account, profile_id: '1') }
  let!(:instagram_inbox) { create(:inbox, channel: instagram_channel, account: account, greeting_enabled: false) }
  let!(:dm_params) { build(:instagram_message_create_event).with_indifferent_access }


  describe '#perform' do
    context 'with direct_message params' do
      it 'creates incoming message in the instagram inbox' do
        instagram_webhook.new(dm_params).consume
        expect(instagram_inbox.contacts.count).to be 1
        expect(instagram_inbox.conversations.count).to be 1
        expect(instagram_inbox.messages.count).to be 1
      end
    end
  end
end
