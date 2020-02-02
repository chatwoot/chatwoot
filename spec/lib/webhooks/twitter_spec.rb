require 'rails_helper'
require 'webhooks/twitter'

describe Webhooks::Twitter do
  subject(:process_twitter_event) { described_class.new(params).consume }

  let!(:account) { create(:account) }
  # FIX ME: recipient id is set to 1 inside event factories
  let!(:twitter_channel) { create(:channel_twitter_profile, account: account, profile_id: '1') }
  let!(:twitter_inbox) { create(:inbox, channel: twitter_channel, account: account) }
  let!(:params) { build(:twitter_message_create_event).with_indifferent_access }

  describe '#perform' do
    context 'with correct params' do
      it 'creates incoming message in the twitter inbox' do
        process_twitter_event
        expect(twitter_inbox.contacts.count).to be 1
        expect(twitter_inbox.conversations.count).to be 1
        expect(twitter_inbox.messages.count).to be 1
      end
    end
  end
end
