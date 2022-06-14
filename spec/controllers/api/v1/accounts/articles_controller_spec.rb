require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Articles', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:portal) { create(:portal, name: 'test_portal', account_id: account.id) }
  let!(:category) { create(:category, name: 'category', portal: portal, account_id: account.id, locale: 'en', slug: 'category_slug') }
  let!(:article) { create(:article, category: category, portal: portal, account_id: account.id, author_id: agent.id) }

  describe 'POST /api/v1/accounts/{account.id}/portals/{portal.slug}/articles' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles", params: {}
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'creates article' do
        article_params = {
          article: {
            category_id: category.id,
            description: 'test description',
            title: 'MyTitle',
            content: 'This is my content.',
            status: :published,
            author_id: agent.id
          }
        }
        post "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles",
             params: article_params,
             headers: agent.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['payload']['title']).to eql('MyTitle')
      end
    end
  end

  describe 'PUT /api/v1/accounts/{account.id}/portals/{portal.slug}/articles/{article.id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles/#{article.id}", params: {}
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'updates category' do
        article_params = {
          article: {
            title: 'MyTitle2',
            description: 'test_description'
          }
        }

        expect(article.title).not_to eql(article_params[:article][:title])

        put "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles/#{article.id}",
            params: article_params,
            headers: agent.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['payload']['title']).to eql(article_params[:article][:title])
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/portals/{portal.slug}/articles/{article.id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles/#{article.id}", params: {}
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'deletes category' do
        delete "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles/#{article.id}",
               headers: agent.create_new_auth_token
        expect(response).to have_http_status(:success)
        deleted_article = Article.find_by(id: article.id)
        expect(deleted_article).to be nil
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/portals/{portal.slug}/articles' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'get all articles' do
        article2 = create(:article, account_id: account.id, portal: portal, category: category, author_id: agent.id)
        expect(article2.id).not_to be nil

        get "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles",
            headers: agent.create_new_auth_token,
            params: { payload: {} }
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['payload'].count).to be 2
      end

      it 'get all articles with searched params' do
        article2 = create(:article, account_id: account.id, portal: portal, category: category, author_id: agent.id)
        expect(article2.id).not_to be nil

        get "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles",
            headers: agent.create_new_auth_token,
            params: { payload: { category_slug: category.slug } }
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['payload'].count).to be 2
      end
    end

    describe 'GET /api/v1/accounts/{account.id}/portals/{portal.slug}/articles/{article.id}' do
      it 'get article' do
        article2 = create(:article, account_id: account.id, portal: portal, category: category, author_id: agent.id)
        expect(article2.id).not_to be nil

        get "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles/#{article2.id}",
            headers: agent.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)

        expect(json_response['payload']['title']).to eq(article2.title)
        expect(json_response['payload']['id']).to eq(article2.id)
      end
    end
  end
end
