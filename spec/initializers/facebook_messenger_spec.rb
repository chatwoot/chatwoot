require 'rails_helper'

describe 'Facebook Messenger webhook', type: :request do
  let(:verify_token) { 'test-fb-verify-token' }
  let(:app_secret) { 'test-fb-app-secret' }
  let(:page_id) { '1234567890' }
  let(:body) do
    {
      object: 'page',
      entry: [{
        id: page_id,
        time: 1_700_000_000_000,
        messaging: [{
          sender: { id: '42' },
          recipient: { id: page_id },
          timestamp: 1_700_000_000_000,
          message: { mid: 'm_1', text: 'hello' }
        }]
      }]
    }.to_json
  end

  def signature_for(payload, secret = app_secret)
    "sha1=#{OpenSSL::HMAC.hexdigest('SHA1', secret, payload)}"
  end

  def post_bot(payload, headers: {})
    post '/bot', params: payload, headers: { 'CONTENT_TYPE' => 'application/json' }.merge(headers)
  end

  before do
    InstallationConfig.where(name: %w[FB_VERIFY_TOKEN FB_APP_SECRET]).delete_all
    GlobalConfig.clear_cache
  end

  describe 'GET /bot' do
    let(:challenge) { 'test-challenge' }

    def verify_with(params)
      get '/bot', params: { 'hub.mode' => 'subscribe', 'hub.challenge' => challenge }.merge(params)
    end

    it 'returns the challenge when the verify token matches' do
      with_modified_env FB_VERIFY_TOKEN: verify_token do
        verify_with('hub.verify_token' => verify_token)
      end

      expect(response.body).to eq(challenge)
    end

    it 'does not return the challenge when the verify token is wrong' do
      with_modified_env FB_VERIFY_TOKEN: verify_token do
        verify_with('hub.verify_token' => 'wrong-token')
      end

      expect(response.body).not_to include(challenge)
    end

    it 'does not return the challenge when the verify token is missing' do
      with_modified_env FB_VERIFY_TOKEN: verify_token do
        verify_with({})
      end

      expect(response.body).not_to include(challenge)
    end

    it 'does not return the challenge when no verify token is configured' do
      with_modified_env FB_VERIFY_TOKEN: '' do
        verify_with('hub.verify_token' => '')
      end

      expect(response.body).not_to include(challenge)
    end
  end

  describe 'POST /bot' do
    it 'enqueues the event when the signature is valid' do
      with_modified_env FB_APP_SECRET: app_secret do
        expect { post_bot(body, headers: { 'X-Hub-Signature' => signature_for(body) }) }
          .to have_enqueued_job(Webhooks::FacebookEventsJob)
      end

      expect(response).to have_http_status(:ok)
    end

    it 'resolves the app secret once per event' do
      allow(Facebook::Messenger.config.provider).to receive(:app_secret_for).and_call_original

      with_modified_env FB_APP_SECRET: app_secret do
        post_bot(body, headers: { 'X-Hub-Signature' => signature_for(body) })
      end

      expect(Facebook::Messenger.config.provider).to have_received(:app_secret_for).once
    end

    it 'rejects the event when the signature is missing' do
      with_modified_env FB_APP_SECRET: app_secret do
        expect { post_bot(body) }.not_to have_enqueued_job(Webhooks::FacebookEventsJob)
      end

      expect(response).to have_http_status(:bad_request)
    end

    it 'rejects the event when the signature is invalid' do
      with_modified_env FB_APP_SECRET: app_secret do
        expect { post_bot(body, headers: { 'X-Hub-Signature' => signature_for(body, 'other-secret') }) }
          .not_to have_enqueued_job(Webhooks::FacebookEventsJob)
      end

      expect(response).to have_http_status(:bad_request)
    end

    it 'rejects the event when no app secret is configured' do
      with_modified_env FB_APP_SECRET: '' do
        expect { post_bot(body) }.not_to have_enqueued_job(Webhooks::FacebookEventsJob)
      end

      expect(response).to have_http_status(:bad_request)
    end
  end
end
