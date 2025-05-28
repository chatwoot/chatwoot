# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Enterprise Articles API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, :administrator, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:portal) { create(:portal, name: 'test_portal', account_id: account.id) }
  let!(:category) { create(:category, name: 'category', portal: portal, account_id: account.id, locale: 'en', slug: 'category_slug') }
  let!(:article) { create(:article, category: category, portal: portal, account_id: account.id, author_id: admin.id) }

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

  describe 'GET /api/v1/accounts/:account_id/portals/:portal_slug/articles/:id' do
    context 'when it is an authenticated user' do
      it 'returns success for agents with knowledge_base_manage permission' do
        get "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles/#{article.id}",
            headers: agent_with_role.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/portals/:portal_slug/articles' do
    let(:article_params) do
      {
        article: {
          category_id: category.id,
          title: 'New Article',
          slug: 'new-article',
          content: 'This is a new article',
          author_id: agent_with_role.id,
          status: 'draft'
        }
      }
    end

    context 'when it is an authenticated user' do
      it 'returns success for agents with knowledge_base_manage permission' do
        post "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles",
             params: article_params,
             headers: agent_with_role.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['payload']['title']).to eq('New Article')
      end
    end
  end

  describe 'PUT /api/v1/accounts/:account_id/portals/:portal_slug/articles/:id' do
    let(:article_params) do
      {
        article: {
          title: 'Updated Article',
          content: 'This is an updated article'
        }
      }
    end

    context 'when it is an authenticated user' do
      it 'returns success for agents with knowledge_base_manage permission' do
        put "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles/#{article.id}",
            params: article_params,
            headers: agent_with_role.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['payload']['title']).to eq('Updated Article')
      end
    end
  end

  describe 'DELETE /api/v1/accounts/:account_id/portals/:portal_slug/articles/:id' do
    context 'when it is an authenticated user' do
      it 'returns success for agents with knowledge_base_manage permission' do
        delete "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles/#{article.id}",
               headers: agent_with_role.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect(Article.find_by(id: article.id)).to be_nil
      end
    end
  end
end
