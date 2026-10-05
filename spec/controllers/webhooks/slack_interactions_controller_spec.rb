require 'rails_helper'

RSpec.describe 'Webhooks::SlackInteractionsController', type: :request do
  describe 'POST /webhooks/slack/interactions' do
    let(:secret) { 'slack-signing-secret' }
    let(:action_id) { 'takeover.confirm' }
    let(:reference) { { 'channel' => 'C123', 'thread_ts' => '1700000000.000100', 'ts' => '1700000050.000200' } }
    let(:response_url) { 'https://hooks.slack.com/actions/T1/1/abc' }
    let(:payload) do
      {
        type: 'block_actions',
        response_url: response_url,
        actions: [{ action_id: action_id, value: reference.to_json }]
      }
    end
    let(:body) { URI.encode_www_form(payload: payload.to_json) }
    let(:timestamp) { Time.current.to_i }
    let(:signature) { "v0=#{OpenSSL::HMAC.hexdigest('SHA256', secret, "v0:#{timestamp}:#{body}")}" }
    let(:headers) do
      {
        'X-Slack-Request-Timestamp' => timestamp.to_s,
        'X-Slack-Signature' => signature,
        'CONTENT_TYPE' => 'application/x-www-form-urlencoded'
      }
    end

    before { allow(GlobalConfigService).to receive(:load).with('SLACK_SIGNING_SECRET', nil).and_return(secret) }

    it 'hands the takeover click to the job' do
      expect { post '/webhooks/slack/interactions', params: body, headers: headers }
        .to have_enqueued_job(SlackPendingReplyJob).with('confirm', reference.to_json, response_url)

      expect(response).to have_http_status(:ok)
    end

    context 'when the agent chooses to just send' do
      let(:action_id) { 'takeover.skip' }

      it 'hands the send only click to the job' do
        expect { post '/webhooks/slack/interactions', params: body, headers: headers }
          .to have_enqueued_job(SlackPendingReplyJob).with('skip', reference.to_json, response_url)
      end
    end

    context 'when the action belongs to no known interaction' do
      let(:action_id) { 'something_else' }

      it 'acknowledges the click without enqueuing the job' do
        expect { post '/webhooks/slack/interactions', params: body, headers: headers }
          .not_to have_enqueued_job(SlackPendingReplyJob)

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the signature is invalid' do
      let(:signature) { 'v0=deadbeef' }

      it 'rejects the request' do
        expect { post '/webhooks/slack/interactions', params: body, headers: headers }
          .not_to have_enqueued_job(SlackPendingReplyJob)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when the request is older than the tolerance' do
      let(:timestamp) { 10.minutes.ago.to_i }

      it 'rejects the request' do
        post '/webhooks/slack/interactions', params: body, headers: headers

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when no signing secret is configured' do
      before { allow(GlobalConfigService).to receive(:load).with('SLACK_SIGNING_SECRET', nil).and_return(nil) }

      it 'rejects the request' do
        with_modified_env SLACK_SIGNING_SECRET: nil do
          post '/webhooks/slack/interactions', params: body, headers: headers

          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end
end
