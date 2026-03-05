require 'rails_helper'

RSpec.describe 'MoEngage Integration API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }

  describe 'POST /api/v1/accounts/:account_id/integrations/moengage' do
    let(:valid_params) do
      {
        hook: {
          settings: {
            workspace_id: 'test-workspace',
            default_inbox_id: inbox.id,
            auto_create_contact: true,
            enable_ai_response: false
          }
        }
      }
    end

    context 'when it is an admin user' do
      it 'creates the moengage integration' do
        expect do
          post "/api/v1/accounts/#{account.id}/integrations/moengage",
               params: valid_params,
               headers: admin.create_new_auth_token,
               as: :json
        end.to change { account.hooks.count }.by(1)

        expect(response).to have_http_status(:created)
        expect(response.parsed_body['app_id']).to eq('moengage')
        expect(response.parsed_body['settings']['workspace_id']).to eq('test-workspace')
      end

      it 'generates a webhook token' do
        post "/api/v1/accounts/#{account.id}/integrations/moengage",
             params: valid_params,
             headers: admin.create_new_auth_token,
             as: :json

        expect(response.parsed_body['settings']['webhook_token']).to be_present
      end

      it 'returns webhook_url in response' do
        post "/api/v1/accounts/#{account.id}/integrations/moengage",
             params: valid_params,
             headers: admin.create_new_auth_token,
             as: :json

        expect(response.parsed_body['webhook_url']).to include('/webhooks/moengage/')
      end

      it 'does not expose sensitive settings in response' do
        params_with_secrets = valid_params.deep_dup
        params_with_secrets[:hook][:settings][:data_api_key] = 'secret-api-key'
        params_with_secrets[:hook][:settings][:webhook_secret] = 'secret-webhook'

        post "/api/v1/accounts/#{account.id}/integrations/moengage",
             params: params_with_secrets,
             headers: admin.create_new_auth_token,
             as: :json

        expect(response.parsed_body['settings']).not_to have_key('data_api_key')
        expect(response.parsed_body['settings']).not_to have_key('webhook_secret')
      end

      it 'returns error when workspace_id is missing' do
        invalid_params = { hook: { settings: { default_inbox_id: inbox.id } } }

        post "/api/v1/accounts/#{account.id}/integrations/moengage",
             params: invalid_params,
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error when inbox is invalid' do
        invalid_params = { hook: { settings: { workspace_id: 'test', default_inbox_id: 99_999 } } }

        post "/api/v1/accounts/#{account.id}/integrations/moengage",
             params: invalid_params,
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when it is an agent user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/integrations/moengage",
             params: valid_params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/integrations/moengage",
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/:account_id/integrations/moengage' do
    let!(:hook) do
      create(:integrations_hook,
             account: account,
             app_id: 'moengage',
             settings: {
               'workspace_id' => 'old-workspace',
               'webhook_token' => 'original-token',
               'default_inbox_id' => inbox.id
             })
    end

    let(:update_params) do
      {
        hook: {
          settings: {
            workspace_id: 'new-workspace',
            data_center: '02'
          }
        }
      }
    end

    context 'when it is an admin user' do
      it 'updates the moengage integration' do
        patch "/api/v1/accounts/#{account.id}/integrations/moengage",
              params: update_params,
              headers: admin.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['settings']['workspace_id']).to eq('new-workspace')
        expect(response.parsed_body['settings']['data_center']).to eq('02')
      end

      it 'preserves webhook_token when updating other settings' do
        patch "/api/v1/accounts/#{account.id}/integrations/moengage",
              params: update_params,
              headers: admin.create_new_auth_token,
              as: :json

        expect(response.parsed_body['settings']['webhook_token']).to eq('original-token')
      end

      it 'preserves existing settings not in update params' do
        patch "/api/v1/accounts/#{account.id}/integrations/moengage",
              params: update_params,
              headers: admin.create_new_auth_token,
              as: :json

        expect(response.parsed_body['settings']['default_inbox_id']).to eq(inbox.id)
      end
    end

    context 'when it is an agent user' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/integrations/moengage",
              params: update_params,
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/:account_id/integrations/moengage' do
    let!(:hook) do
      create(:integrations_hook,
             account: account,
             app_id: 'moengage',
             settings: {
               'workspace_id' => 'test-workspace',
               'webhook_token' => 'test-token',
               'default_inbox_id' => inbox.id
             })
    end

    context 'when it is an admin user' do
      it 'deletes the moengage integration' do
        expect do
          delete "/api/v1/accounts/#{account.id}/integrations/moengage",
                 headers: admin.create_new_auth_token,
                 as: :json
        end.to change { account.hooks.count }.by(-1)

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when it is an agent user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/integrations/moengage",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when hook does not exist' do
      before { hook.destroy! }

      it 'returns not found' do
        delete "/api/v1/accounts/#{account.id}/integrations/moengage",
               headers: admin.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/integrations/moengage/regenerate_token' do
    let!(:hook) do
      create(:integrations_hook,
             account: account,
             app_id: 'moengage',
             settings: {
               'workspace_id' => 'test-workspace',
               'webhook_token' => 'old-token',
               'default_inbox_id' => inbox.id
             })
    end

    context 'when it is an admin user' do
      it 'regenerates the webhook token' do
        post "/api/v1/accounts/#{account.id}/integrations/moengage/regenerate_token",
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['settings']['webhook_token']).not_to eq('old-token')
        expect(response.parsed_body['settings']['webhook_token']).to be_present
      end

      it 'updates the webhook_url with new token' do
        post "/api/v1/accounts/#{account.id}/integrations/moengage/regenerate_token",
             headers: admin.create_new_auth_token,
             as: :json

        new_token = response.parsed_body['settings']['webhook_token']
        expect(response.parsed_body['webhook_url']).to include(new_token)
      end

      it 'preserves other settings' do
        post "/api/v1/accounts/#{account.id}/integrations/moengage/regenerate_token",
             headers: admin.create_new_auth_token,
             as: :json

        expect(response.parsed_body['settings']['workspace_id']).to eq('test-workspace')
        expect(response.parsed_body['settings']['default_inbox_id']).to eq(inbox.id)
      end
    end

    context 'when it is an agent user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/integrations/moengage/regenerate_token",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
