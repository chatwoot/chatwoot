require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Categories', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:portal) { create(:portal, name: 'test_portal', account_id: account.id) }
  let!(:category) { create(:category, name: 'category', portal: portal, account_id: account.id, slug: 'category_slug') }

  describe 'POST /api/v1/accounts/{account.id}/portals/{portal.slug}/categories' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/categories", params: {}
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      category_params = {
        category: {
          name: 'test_category',
          description: 'test_description',
          position: 1,
          locale: 'es',
          slug: 'test_category_1'
        }
      }

      it 'creates category' do
        post "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/categories",
             params: category_params,
             headers: agent.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['payload']['name']).to eql('test_category')
      end

      it 'will throw an error on locale, category_id uniqueness' do
        post "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/categories",
             params: category_params,
             headers: agent.create_new_auth_token

        post "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/categories",
             params: category_params,
             headers: agent.create_new_auth_token
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eql('Locale should be unique in the category and portal')
      end

      it 'will throw an error slug presence' do
        category_params = {
          category: {
            name: 'test_category',
            description: 'test_description',
            position: 1,
            locale: 'es'
          }
        }

        post "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/categories",
             params: category_params,
             headers: agent.create_new_auth_token
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eql("Slug can't be blank")
      end
    end
  end

  describe 'PUT /api/v1/accounts/{account.id}/portals/{portal.slug}/categories/{category.id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/categories/#{category.id}", params: {}
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

        put "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/categories/#{category.id}",
            params: category_params,
            headers: agent.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['payload']['name']).to eql(category_params[:category][:name])
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/portals/{portal.slug}/categories/{category.id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/categories/#{category.id}", params: {}
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'deletes category' do
        delete "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/categories/#{category.id}",
               headers: agent.create_new_auth_token
        expect(response).to have_http_status(:success)
        deleted_category = Category.find_by(id: category.id)
        expect(deleted_category).to be nil
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/portals/{portal.slug}/categories' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/categories"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'get all portals' do
        category2 = create(:category, name: 'test_category_2', portal: portal, locale: 'es', slug: 'category_slug_2')
        expect(category2.id).not_to be nil

        get "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/categories",
            headers: agent.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['payload'].count).to be 2
      end
    end
  end
end
