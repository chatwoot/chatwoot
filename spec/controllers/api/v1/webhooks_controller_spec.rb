require 'rails_helper'

RSpec.describe 'Twitter webhooks', type: :request do
  let(:consumer_secret) { 'test-consumer-secret' }
  let(:account) { create(:account) }
  let(:twitter_channel) { create(:channel_twitter_profile, account: account, profile_id: '1') }
  let!(:twitter_inbox) { create(:inbox, channel: twitter_channel, account: account, greeting_enabled: false) }
  let(:body) { build(:twitter_message_create_event).to_json }

  def signature_for(payload, secret = consumer_secret)
    "sha256=#{Base64.strict_encode64(OpenSSL::HMAC.digest('SHA256', secret, payload))}"
  end

  def post_event(payload, signature: nil, path: '/webhooks/twitter')
    headers = { 'CONTENT_TYPE' => 'application/json' }
    headers['X-Twitter-Webhooks-Signature'] = signature if signature
    post path, params: payload, headers: headers
  end

  around do |example|
    with_modified_env('TWITTER_CONSUMER_SECRET' => consumer_secret) { example.run }
  end

  describe 'POST /webhooks/twitter' do
    it 'processes events with a valid signature' do
      post_event(body, signature: signature_for(body))

      expect(response).to have_http_status(:ok)
      expect(twitter_inbox.messages.count).to eq 1
    end

    it 'rejects events without a signature' do
      post_event(body)

      expect(response).to have_http_status(:unauthorized)
      expect(twitter_inbox.messages.count).to eq 0
    end

    it 'rejects events signed with a different secret' do
      post_event(body, signature: signature_for(body, 'other-secret'))

      expect(response).to have_http_status(:unauthorized)
      expect(twitter_inbox.messages.count).to eq 0
    end

    it 'rejects events when the consumer secret is not configured' do
      with_modified_env('TWITTER_CONSUMER_SECRET' => nil) do
        post_event(body, signature: signature_for(body))
      end

      expect(response).to have_http_status(:unauthorized)
      expect(twitter_inbox.messages.count).to eq 0
    end

    it 'ignores event data passed outside the signed body' do
      signed_body = '{}'
      query = build(:twitter_message_create_event).to_query

      post_event(signed_body, signature: signature_for(signed_body), path: "/webhooks/twitter?#{query}")

      expect(response).to have_http_status(:ok)
      expect(twitter_inbox.messages.count).to eq 0
    end
  end

  describe 'GET /webhooks/twitter' do
    it 'responds to the challenge with the signed token' do
      get '/webhooks/twitter', params: { crc_token: 'MjM4MzI3Mj+/I5NjQ_y-MDYzOTk0Ng==' }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['response_token']).to eq signature_for('MjM4MzI3Mj+/I5NjQ_y-MDYzOTk0Ng==')
    end

    it 'does not sign tokens that could be used as an event body' do
      get '/webhooks/twitter', params: { crc_token: body }

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).not_to include('response_token')
    end
  end
end
