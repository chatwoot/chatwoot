require 'rails_helper'

RSpec.describe 'Twitter::CallbacksController', type: :request do
  let(:twitter_client) { instance_double(::Twitty::Facade) }
  let(:twitter_response) { instance_double(::Twitty::Response, status: '200', body: { message: 'Valid' }) }
  let(:raw_response) do
    object_double('raw_response', body: 'oauth_token=1&oauth_token_secret=1&user_id=100&screen_name=chatwoot')
  end
  let(:account) { create(:account) }
  let(:webhook_service) { double }

  before do
    allow(::Twitty::Facade).to receive(:new).and_return(twitter_client)
    allow(::Redis::Alfred).to receive(:get).and_return(account.id)
    allow(::Redis::Alfred).to receive(:delete).and_return('OK')
    allow(twitter_client).to receive(:access_token).and_return(twitter_response)
    allow(twitter_response).to receive(:raw_response).and_return(raw_response)
    allow(::Twitter::WebhookSubscribeService).to receive(:new).and_return(webhook_service)
  end

  describe 'GET /twitter/callback' do
    it 'creates inboxes if subscription is successful' do
      allow(webhook_service).to receive(:perform).and_return true
      get twitter_callback_url
      account.reload
      expect(response).to redirect_to app_twitter_inbox_agents_url(account_id: account.id, inbox_id: account.inboxes.last.id)
      expect(account.inboxes.count).to be 1
      expect(account.twitter_profiles.last.inbox.name).to eq 'chatwoot'
      expect(account.twitter_profiles.last.profile_id).to eq '100'
    end

    it 'does not create inbox if subscription fails' do
      allow(webhook_service).to receive(:perform).and_raise StandardError
      get twitter_callback_url
      account.reload
      expect(response).to redirect_to app_new_twitter_inbox_url(account_id: account.id)
      expect(account.inboxes.count).to be 0
    end
  end
end
