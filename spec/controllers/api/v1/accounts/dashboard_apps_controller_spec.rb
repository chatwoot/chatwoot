require 'rails_helper'

RSpec.describe 'DashboardAppsController', type: :request do
  let(:account) { create(:account) }

  describe 'GET /api/v1/accounts/{account.id}/dashboard_apps' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/dashboard_apps"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:user) { create(:user, account: account) }
      let!(:dashboard_app) { create(:dashboard_app, user: user, account: account) }

      it 'returns all dashboard_apps in the account' do
        get "/api/v1/accounts/#{account.id}/dashboard_apps",
            headers: user.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_body = JSON.parse(response.body)
        expect(response_body.first['title']).to eq(dashboard_app.title)
        expect(response_body.first['content']).to eq(dashboard_app.content)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/dashboard_apps/:id' do
    let(:user) { create(:user, account: account) }
    let!(:dashboard_app) { create(:dashboard_app, user: user, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/dashboard_apps/#{dashboard_app.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'shows the dashboard app' do
        get "/api/v1/accounts/#{account.id}/dashboard_apps/#{dashboard_app.id}",
            headers: user.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(dashboard_app.title)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/dashboard_apps' do
    let(:payload) { { dashboard_app: { title: 'CRM Dashboard', content: [{ type: 'frame', url: 'https://link.com' }] } } }
    let(:invalid_type_payload) { { dashboard_app: { title: 'CRM Dashboard', content: [{ type: 'dda', url: 'https://link.com' }] } } }
    let(:invalid_url_payload) { { dashboard_app: { title: 'CRM Dashboard', content: [{ type: 'frame', url: 'com' }] } } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect { post "/api/v1/accounts/#{account.id}/dashboard_apps", params: payload }.not_to change(CustomFilter, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:user) { create(:user, account: account) }

      it 'creates the dashboard app' do
        expect do
          post "/api/v1/accounts/#{account.id}/dashboard_apps", headers: user.create_new_auth_token,
                                                                params: payload
        end.to change(DashboardApp, :count).by(1)

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['title']).to eq 'CRM Dashboard'
        expect(json_response['content'][0]['link']).to eq payload[:dashboard_app][:content][0][:link]
        expect(json_response['content'][0]['type']).to eq payload[:dashboard_app][:content][0][:type]
      end

      it 'does not create the dashboard app if invalid URL' do
        expect do
          post "/api/v1/accounts/#{account.id}/dashboard_apps", headers: user.create_new_auth_token,
                                                                params: invalid_url_payload
        end.not_to change(DashboardApp, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq 'Content : Invalid data'
      end

      it 'does not create the dashboard app if invalid type' do
        expect do
          post "/api/v1/accounts/#{account.id}/dashboard_apps", headers: user.create_new_auth_token,
                                                                params: invalid_type_payload
        end.not_to change(DashboardApp, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/dashboard_apps/:id' do
    let(:payload) { { dashboard_app: { title: 'CRM Dashboard', content: [{ type: 'frame', url: 'https://link.com' }] } } }
    let(:user) { create(:user, account: account) }
    let!(:dashboard_app) { create(:dashboard_app, user: user, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/dashboard_apps/#{dashboard_app.id}",
            params: payload

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'updates the dashboard app' do
        patch "/api/v1/accounts/#{account.id}/dashboard_apps/#{dashboard_app.id}",
              headers: user.create_new_auth_token,
              params: payload,
              as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(dashboard_app.reload.title).to eq('CRM Dashboard')
        expect(json_response['content'][0]['link']).to eq payload[:dashboard_app][:content][0][:link]
        expect(json_response['content'][0]['type']).to eq payload[:dashboard_app][:content][0][:type]
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/dashboard_apps/:id' do
    let(:user) { create(:user, account: account) }
    let!(:dashboard_app) { create(:dashboard_app, user: user, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/dashboard_apps/#{dashboard_app.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated admin user' do
      it 'deletes dashboard app' do
        delete "/api/v1/accounts/#{account.id}/dashboard_apps/#{dashboard_app.id}",
               headers: user.create_new_auth_token,
               as: :json
        expect(response).to have_http_status(:no_content)
        expect(user.dashboard_apps.count).to be 0
      end
    end
  end
end
