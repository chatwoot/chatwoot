require 'rails_helper'
require 'webhooks/twitter'

describe Webhooks::Twitter do
  subject(:twitter_webhook) { described_class }

  let!(:account) { create(:account) }
  # FIX ME: recipient id is set to 1 inside event factories
  let!(:twitter_channel) { create(:channel_twitter_profile, account: account, profile_id: '1', tweets_enabled: true) }
  let!(:twitter_inbox) { create(:inbox, channel: twitter_channel, account: account, greeting_enabled: false) }
  let!(:dm_params) { build(:twitter_message_create_event).with_indifferent_access }
  let!(:dm_image_params) { build(:twitter_dm_image_event).with_indifferent_access }
  let!(:tweet_params) { build(:tweet_create_event).with_indifferent_access }
  let!(:tweet_params_from_blocked_user) { build(:tweet_create_event, user_has_blocked: true).with_indifferent_access }

  describe '#perform' do
    context 'with direct_message params' do
      it 'creates incoming message in the twitter inbox' do
        twitter_webhook.new(dm_params).consume
        expect(twitter_inbox.contacts.count).to be 1
        expect(twitter_inbox.conversations.count).to be 1
        expect(twitter_inbox.messages.count).to be 1
      end
    end

    context 'with direct_message attachment params' do
      before do
        stub_request(:get, 'http://pbs.twimg.com/media/DOhM30VVwAEpIHq.jpg')
          .to_return(status: 200, body: '', headers: {})
      end

      it 'creates incoming message with attachments in the twitter inbox' do
        twitter_webhook.new(dm_image_params).consume
        expect(twitter_inbox.contacts.count).to be 1
        expect(twitter_inbox.conversations.count).to be 1
        expect(twitter_inbox.messages.count).to be 1
        expect(twitter_inbox.messages.last.attachments.count).to be 1
      end
    end

    context 'with tweet_params params' do
      it 'does not create incoming message in the twitter inbox if it is a blocked user' do
        twitter_webhook.new(tweet_params_from_blocked_user).consume
        expect(twitter_inbox.contacts.count).to be 0
        expect(twitter_inbox.conversations.count).to be 0
        expect(twitter_inbox.messages.count).to be 0
      end

      it 'creates incoming message in the twitter inbox' do
        twitter_webhook.new(tweet_params).consume
        twitter_inbox.reload
        expect(twitter_inbox.contacts.count).to be 1
        expect(twitter_inbox.conversations.count).to be 1
        expect(twitter_inbox.messages.count).to be 1
      end
    end

    context 'with tweet_enabled flag disabled' do
      before do
        twitter_channel.update(tweets_enabled: false)
      end

      it 'does not create incoming message in the twitter inbox for tweet' do
        twitter_webhook.new(tweet_params).consume
        expect(twitter_inbox.contacts.count).to be 0
        expect(twitter_inbox.conversations.count).to be 0
        expect(twitter_inbox.messages.count).to be 0
      end

      it 'creates incoming message in the twitter inbox' do
        twitter_webhook.new(dm_params).consume
        expect(twitter_inbox.contacts.count).to be 1
        expect(twitter_inbox.conversations.count).to be 1
        expect(twitter_inbox.messages.count).to be 1
      end
    end
  end
end
