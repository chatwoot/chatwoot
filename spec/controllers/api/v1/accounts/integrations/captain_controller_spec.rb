require 'rails_helper'

RSpec.describe 'Captain Integrations API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }

  describe 'GET /api/v1/accounts/{account.id}/integrations/captain/sso_url' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get sso_url_api_v1_account_integrations_captain_url(account_id: account.id),
            params: {},
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'return unauthorized if agent' do
        get sso_url_api_v1_account_integrations_captain_url(account_id: account.id),
            params: {},
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns 404 if hook is not available' do
        get sso_url_api_v1_account_integrations_captain_url(account_id: account.id),
            params: {},
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'returns sso url if hook is available' do
        InstallationConfig.where(name: 'CAPTAIN_APP_URL').first_or_create(value: 'https://app.chatwoot.com')

        hook = create(:integrations_hook, account: account, app_id: 'captain', settings: {
                        access_token: SecureRandom.hex,
                        account_email: Faker::Internet.email,
                        account_id: '1',
                        assistant_id: '1',
                        inbox_ids: '1'
                      })

        get sso_url_api_v1_account_integrations_captain_url(account_id: account.id),
            params: {},
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        data = response.parsed_body
        params_string = "token=#{URI.encode_www_form_component(hook['settings']['access_token'])}" \
                        "&email=#{URI.encode_www_form_component(hook['settings']['account_email'])}" \
                        "&account_id=#{URI.encode_www_form_component(hook['settings']['account_id'])}"

        sso_url = "https://app.chatwoot.com/sso?#{params_string}"
        expect(data['sso_url']).to eq(sso_url)
      end
    end
  end
end
