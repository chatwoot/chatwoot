require 'rails_helper'

RSpec.describe 'ExternalAppContextsController', type: :request do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:hmac_key) { 'test_external_app_hmac_secret' }
  let(:route_name) { 'external_app_index' }
  let(:route_full_path) { "/app/accounts/#{account.id}/calendar?conversation_id=#{conversation.display_id}" }
  let(:request_params) do
    {
      conversation_id: conversation.display_id,
      inbox_id: conversation.inbox_id,
      route_name: route_name,
      route_full_path: route_full_path
    }
  end

  before do
    allow(GlobalConfigService).to receive(:load).and_call_original
    allow(GlobalConfigService).to receive(:load).with('EXTERNAL_APP_HMAC_KEY', '').and_return(hmac_key)
  end

  describe 'GET /api/v1/accounts/{account.id}/external_app_context' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/external_app_context"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns unauthorized without conversation access' do
        get "/api/v1/accounts/#{account.id}/external_app_context",
            headers: agent.create_new_auth_token,
            params: request_params,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns signed context when the agent can access the conversation inbox' do
        create(:inbox_member, user: agent, inbox: conversation.inbox)

        get "/api/v1/accounts/#{account.id}/external_app_context",
            headers: agent.create_new_auth_token,
            params: request_params,
            as: :json

        expect(response).to have_http_status(:success)

        response_body = response.parsed_body
        expect(response_body['event']).to eq('externalAppContext')
        expect(response_body['signatureAlgorithm']).to eq('HMAC-SHA256')
        expect(response_body['data']['conversation']).to eq({
                                                           'id' => conversation.display_id,
                                                           'inboxId' => conversation.inbox_id
                                                         })
        expect(response_body['data']['route']).to eq({
                                                    'name' => route_name,
                                                    'fullPath' => route_full_path
                                                  })

        expected_payload = {
          account: {
            id: account.id,
            name: account.name
          },
          currentAgent: {
            id: agent.id,
            name: agent.name,
            email: agent.email
          },
          conversation: {
            id: conversation.display_id,
            inboxId: conversation.inbox_id
          },
          route: {
            name: route_name,
            fullPath: route_full_path
          }
        }.to_json
        expected_signature = OpenSSL::HMAC.hexdigest(
          'SHA256',
          hmac_key,
          "#{response_body['timestamp']}.#{response_body['nonce']}.#{expected_payload}"
        )

        expect(response_body['signature']).to eq(expected_signature)
      end
    end
  end
end
