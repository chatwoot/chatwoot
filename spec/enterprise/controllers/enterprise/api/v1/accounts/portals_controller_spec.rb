# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Enterprise Portal API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, :administrator, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:portal) { create(:portal, name: 'test_portal', account_id: account.id) }

  # Create a custom role with knowledge_base_manage permission
  let!(:custom_role) { create(:custom_role, account: account, permissions: ['knowledge_base_manage']) }
  # Create user without account
  let!(:agent_with_role) { create(:user) }
  # Then create account_user association with custom_role
  let(:agent_with_role_account_user) do
    create(:account_user, user: agent_with_role, account: account, role: :agent, custom_role: custom_role)
  end

  # Ensure the account_user with custom role is created before tests run
  before do
    agent_with_role_account_user
  end

  describe 'GET /api/v1/accounts/:account_id/portals' do
    context 'when it is an authenticated user' do
      it 'returns success for agents with knowledge_base_manage permission' do
        get "/api/v1/accounts/#{account.id}/portals",
            headers: agent_with_role.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET /api/v1/accounts/:account_id/portals/:portal_slug' do
    context 'when it is an authenticated user' do
      it 'returns success for agents with knowledge_base_manage permission' do
        get "/api/v1/accounts/#{account.id}/portals/#{portal.slug}",
            headers: agent_with_role.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['name']).to eq('test_portal')
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/portals' do
    let(:portal_params) do
      {  portal: {
        name: 'test_portal',
        slug: 'test_kbase',
        custom_domain: 'https://support.chatwoot.dev'
      } }
    end

    context 'when it is an authenticated user' do
      it 'restricts portal creation for agents with knowledge_base_manage permission' do
        post "/api/v1/accounts/#{account.id}/portals",
             params: portal_params,
             headers: agent_with_role.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PUT /api/v1/accounts/:account_id/portals/:portal_slug' do
    let(:portal_params) do
      { portal: { name: 'updated_portal' } }
    end

    context 'when it is an authenticated user' do
      it 'returns success for agents with knowledge_base_manage permission' do
        put "/api/v1/accounts/#{account.id}/portals/#{portal.slug}",
            params: portal_params,
            headers: agent_with_role.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['name']).to eq('updated_portal')
      end
    end
  end
end
