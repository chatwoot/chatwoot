require 'rails_helper'

RSpec.describe 'Integration Hooks API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:params) { { app_id: 'dialogflow', inbox_id: inbox.id, settings: { project_id: 'xx', credentials: { test: 'test' }, region: 'europe-west1' } } }

  describe 'POST /api/v1/accounts/{account.id}/integrations/hooks' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post api_v1_account_integrations_hooks_url(account_id: account.id),
             params: params,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'return unauthorized if agent' do
        post api_v1_account_integrations_hooks_url(account_id: account.id),
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'creates hooks if admin' do
        post api_v1_account_integrations_hooks_url(account_id: account.id),
             params: params,
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        data = response.parsed_body
        expect(data['app_id']).to eq params[:app_id]
      end

      it 'validates Cloudflare RealtimeKit credentials before creating the hook' do
        allow(Integrations::Cloudflare::RealtimeKitCredentialsValidator).to receive(:validate)
          .and_return(Integrations::Cloudflare::RealtimeKitCredentialsValidator::Result.new(false, :invalid_api_token))

        post api_v1_account_integrations_hooks_url(account_id: account.id),
             params: { app_id: 'dyte', settings: { account_id: 'bad', app_id: 'bad', api_token: 'bad' } },
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['message']).to include(I18n.t('errors.cloudflare.realtimekit.invalid_api_token'))
      end

      it 'does not create Shopify hooks when the installation switch is disabled' do
        allow(GlobalConfigService).to receive(:load)
          .with('ENABLE_SHOPIFY_INTEGRATION', 'false')
          .and_return(false)

        expect do
          post api_v1_account_integrations_hooks_url(account_id: account.id),
               params: { hook: { app_id: 'shopify' } },
               headers: admin.create_new_auth_token,
               as: :json
        end.not_to change(Integrations::Hook, :count)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/integrations/hooks/{hook_id}' do
    let(:hook) { create(:integrations_hook, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch api_v1_account_integrations_hook_url(account_id: account.id, id: hook.id),
              params: params,
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'return unauthorized if agent' do
        patch api_v1_account_integrations_hook_url(account_id: account.id, id: hook.id),
              params: params,
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'updates hook if admin' do
        patch api_v1_account_integrations_hook_url(account_id: account.id, id: hook.id),
              params: params,
              headers: admin.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)
        data = response.parsed_body
        expect(data['app_id']).to eq 'slack'
      end

      it 'does not update Shopify hooks when the account feature is disabled' do
        shopify_hook = create(:integrations_hook, :shopify, account: account)
        allow(GlobalConfigService).to receive(:load)
          .with('ENABLE_SHOPIFY_INTEGRATION', 'false')
          .and_return(true)

        patch api_v1_account_integrations_hook_url(account_id: account.id, id: shopify_hook.id),
              params: { hook: { status: 'disabled' } },
              headers: admin.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:not_found)
        expect(shopify_hook.reload).to be_enabled
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/integrations/hooks/{hook_id}/process_event' do
    let(:hook) { create(:integrations_hook, account: account) }
    let(:params) { { event: 'rephrase', payload: { test: 'test' } } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post process_event_api_v1_account_integrations_hook_url(account_id: account.id, id: hook.id),
             params: params,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'will process the events' do
        post process_event_api_v1_account_integrations_hook_url(account_id: account.id, id: hook.id),
             params: params,
             headers: agent.create_new_auth_token,
             as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq 'No processor found'
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/integrations/hooks/{hook_id}' do
    let(:hook) { create(:integrations_hook, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete api_v1_account_integrations_hook_url(account_id: account.id, id: hook.id),
               as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'return unauthorized if agent' do
        delete api_v1_account_integrations_hook_url(account_id: account.id, id: hook.id),
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'updates hook if admin' do
        delete api_v1_account_integrations_hook_url(account_id: account.id, id: hook.id),
               headers: admin.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect(Integrations::Hook.exists?(hook.id)).to be false
      end

      it 'does not delete Shopify hooks when the account feature is disabled' do
        shopify_hook = create(:integrations_hook, :shopify, account: account)
        allow(GlobalConfigService).to receive(:load)
          .with('ENABLE_SHOPIFY_INTEGRATION', 'false')
          .and_return(true)

        delete api_v1_account_integrations_hook_url(account_id: account.id, id: shopify_hook.id),
               headers: admin.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:not_found)
        expect(Integrations::Hook.exists?(shopify_hook.id)).to be true
      end
    end
  end
end
