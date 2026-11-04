require 'rails_helper'

RSpec.describe 'Api::V1::Integrations::Webhooks' do
  describe 'POST /api/v1/integrations/webhooks' do
    let(:payload) { { type: 'url_verification', challenge: 'abc' } }
    let(:secret) { 'slack-signing-secret' }

    def slack_headers(body, timestamp: Time.current.to_i, signature: nil)
      signature ||= "v0=#{OpenSSL::HMAC.hexdigest('SHA256', secret, "v0:#{timestamp}:#{body}")}"
      { 'X-Slack-Request-Timestamp' => timestamp.to_s, 'X-Slack-Signature' => signature, 'CONTENT_TYPE' => 'application/json' }
    end

    context 'when no signing secret is configured' do
      before { allow(GlobalConfigService).to receive(:load).with('SLACK_SIGNING_SECRET', nil).and_return(nil) }

      it 'skips verification and processes the webhook' do
        with_modified_env SLACK_SIGNING_SECRET: nil do
          builder = instance_double(Integrations::Slack::IncomingMessageBuilder, perform: true)
          allow(Integrations::Slack::IncomingMessageBuilder).to receive(:new).and_return(builder)

          post '/api/v1/integrations/webhooks', params: {}

          expect(response).to have_http_status(:success)
        end
      end
    end

    context 'when a signing secret is configured only via ENV and config reconciliation left a blank row' do
      before { InstallationConfig.create!(name: 'SLACK_SIGNING_SECRET', value: nil, locked: false) }

      it 'still verifies the signature' do
        with_modified_env SLACK_SIGNING_SECRET: secret do
          expect(Integrations::Slack::IncomingMessageBuilder).not_to receive(:new)
          body = payload.to_json

          post '/api/v1/integrations/webhooks', params: body, headers: slack_headers(body, signature: 'v0=deadbeef')

          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    context 'when a signing secret is configured via installation config' do
      before { allow(GlobalConfigService).to receive(:load).with('SLACK_SIGNING_SECRET', nil).and_return(secret) }

      it 'processes the webhook when the signature is valid' do
        builder = instance_double(Integrations::Slack::IncomingMessageBuilder, perform: true)
        allow(Integrations::Slack::IncomingMessageBuilder).to receive(:new).and_return(builder)
        body = payload.to_json

        post '/api/v1/integrations/webhooks', params: body, headers: slack_headers(body)

        expect(response).to have_http_status(:success)
      end

      it 'rejects the webhook when the signature is invalid' do
        expect(Integrations::Slack::IncomingMessageBuilder).not_to receive(:new)
        body = payload.to_json

        post '/api/v1/integrations/webhooks', params: body, headers: slack_headers(body, signature: 'v0=deadbeef')

        expect(response).to have_http_status(:unauthorized)
      end

      it 'rejects a replayed request with a stale timestamp' do
        expect(Integrations::Slack::IncomingMessageBuilder).not_to receive(:new)
        body = payload.to_json

        post '/api/v1/integrations/webhooks', params: body, headers: slack_headers(body, timestamp: 10.minutes.ago.to_i)

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
