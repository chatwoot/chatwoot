# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Enterprise Categories API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:portal) { create(:portal, name: 'test_portal', account_id: account.id, config: { allowed_locales: %w[en es] }) }
  let!(:category) { create(:category, name: 'category', portal: portal, account_id: account.id, slug: 'category_slug', position: 1) }

  # Create a custom role with knowledge_base_manage permission
  let!(:custom_role) { create(:custom_role, account: account, permissions: ['knowledge_base_manage']) }
  let!(:agent_with_role) { create(:user) }
  let(:agent_with_role_account_user) do
    create(:account_user, user: agent_with_role, account: account, role: :agent, custom_role: custom_role)
  end

  # Ensure the account_user with custom role is created before tests run
  before do
    agent_with_role_account_user
  end

  describe 'GET /api/v1/accounts/:account_id/portals/:portal_slug/categories' do
    context 'when it is an authenticated user' do
      it 'returns success for agents with knowledge_base_manage permission' do
        get "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/categories",
            headers: agent_with_role.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET /api/v1/accounts/:account_id/portals/:portal_slug/categories/:id' do
    context 'when it is an authenticated user' do
      it 'returns success for agents with knowledge_base_manage permission' do
        get "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/categories/#{category.id}",
            headers: agent_with_role.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['payload']['name']).to eq('category')
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/portals/:portal_slug/categories' do
    let(:category_params) do
      {
        category: {
          name: 'New Category',
          slug: 'new-category',
          locale: 'en',
          description: 'This is a new category'
        }
      }
    end

    context 'when it is an authenticated user' do
      it 'returns success for agents with knowledge_base_manage permission' do
        post "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/categories",
             params: category_params,
             headers: agent_with_role.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['payload']['name']).to eq('New Category')
      end
    end
  end

  describe 'PUT /api/v1/accounts/:account_id/portals/:portal_slug/categories/:id' do
    let(:category_params) do
      {
        category: {
          name: 'Updated Category',
          description: 'This is an updated category'
        }
      }
    end

    context 'when it is an authenticated user' do
      it 'returns success for agents with knowledge_base_manage permission' do
        put "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/categories/#{category.id}",
            params: category_params,
            headers: agent_with_role.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['payload']['name']).to eq('Updated Category')
      end
    end
  end

  describe 'DELETE /api/v1/accounts/:account_id/portals/:portal_slug/categories/:id' do
    context 'when it is an authenticated user' do
      it 'returns success for agents with knowledge_base_manage permission' do
        delete "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/categories/#{category.id}",
               headers: agent_with_role.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
      end
    end
  end
end
