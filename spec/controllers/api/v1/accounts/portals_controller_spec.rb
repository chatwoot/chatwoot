require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Portals', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:portal) { create(:portal, slug: 'portal-1', name: 'test_portal', account_id: account.id) }

  describe 'GET /api/v1/accounts/{account.id}/portals' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/portals"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'get all portals' do
        portal2 = create(:portal, name: 'test_portal_2', account_id: account.id, slug: 'portal-2')
        expect(portal2.id).not_to be nil
        get "/api/v1/accounts/#{account.id}/portals",
            headers: agent.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response.count).to be 2
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/portals/{portal.slug}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/portals"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'get one portals' do
        get "/api/v1/accounts/#{account.id}/portals/#{portal.slug}",
            headers: agent.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['name']).to eq portal.name
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/portals' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/portals", params: {}
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'creates portal' do
        portal_params = {
          portal: {
            name: 'test_portal',
            slug: 'test_kbase'
          }
        }
        post "/api/v1/accounts/#{account.id}/portals",
             params: portal_params,
             headers: agent.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['name']).to eql('test_portal')
      end
    end
  end

  describe 'PUT /api/v1/accounts/{account.id}/portals/{portal.slug}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/portals/#{portal.slug}", params: {}
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'updates portal' do
        portal_params = {
          portal: {
            name: 'updated_test_portal'
          }
        }

        expect(portal.name).to eql('test_portal')

        put "/api/v1/accounts/#{account.id}/portals/#{portal.slug}",
            params: portal_params,
            headers: agent.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['name']).to eql(portal_params[:portal][:name])
      end

      it 'archive portal' do
        portal_params = {
          portal: {
            archived: true
          }
        }

        expect(portal.archived).to be_falsy

        put "/api/v1/accounts/#{account.id}/portals/#{portal.slug}",
            params: portal_params,
            headers: agent.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['archived']).to eql(portal_params[:portal][:archived])

        portal.reload
        expect(portal.archived).to be_truthy
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/portals/{portal.slug}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/portals/#{portal.slug}", params: {}
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'deletes portal' do
        delete "/api/v1/accounts/#{account.id}/portals/#{portal.slug}",
               headers: agent.create_new_auth_token
        expect(response).to have_http_status(:success)
        deleted_portal = Portal.find_by(id: portal.slug)
        expect(deleted_portal).to be nil
      end
    end
  end
end
