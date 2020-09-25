require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Kbase::Categories', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:portal) { create(:kbase_portal, name: 'test_portal', account_id: account.id) }
  let!(:category) { create(:kbase_category, name: 'category', portal: portal, account_id: account.id) }

  describe 'POST /api/v1/accounts/{account.id}/kbase/portals/{portal.id}/categories' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/kbase/portals/#{portal.id}/categories", params: {}
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'creates category' do
        category_params = {
          category: {
            name: 'test_category',
            description: 'test_description',
            position: 1
          }
        }
        post "/api/v1/accounts/#{account.id}/kbase/portals/#{portal.id}/categories",
             params: category_params,
             headers: agent.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['payload']['name']).to eql('test_category')
      end
    end
  end

  describe 'PUT /api/v1/accounts/{account.id}/kbase/portals/{portal.id}/categories/{category.id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/kbase/portals/#{portal.id}/categories/#{category.id}", params: {}
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'updates category' do
        category_params = {
          category: {
            name: 'test_category_2',
            description: 'test_description',
            position: 1
          }
        }

        expect(category.name).not_to eql(category_params[:category][:name])

        put "/api/v1/accounts/#{account.id}/kbase/portals/#{portal.id}/categories/#{category.id}",
            params: category_params,
            headers: agent.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['payload']['name']).to eql(category_params[:category][:name])
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/kbase/portals/{portal.id}/categories/{category.id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/kbase/portals/#{portal.id}/categories/#{category.id}", params: {}
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'deletes category' do
        delete "/api/v1/accounts/#{account.id}/kbase/portals/#{portal.id}/categories/#{category.id}",
               headers: agent.create_new_auth_token
        expect(response).to have_http_status(:success)
        deleted_category = Kbase::Category.find_by(id: category.id)
        expect(deleted_category).to be nil
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/kbase/portals/{portal.id}/categories' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/kbase/portals/#{portal.id}/categories"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'get all portals' do
        category2 = create(:kbase_category, name: 'test_category_2', portal: portal)
        expect(category2.id).not_to be nil

        get "/api/v1/accounts/#{account.id}/kbase/portals/#{portal.id}/categories",
            headers: agent.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['payload'].count).to be 2
      end
    end
  end
end
