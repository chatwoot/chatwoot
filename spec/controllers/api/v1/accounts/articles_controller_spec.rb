require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Articles', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:portal) { create(:portal, name: 'test_portal', account_id: account.id) }
  let!(:category) { create(:category, name: 'category', portal: portal, account_id: account.id, locale: 'en', slug: 'category_slug') }
  let!(:article) { create(:article, category: category, portal: portal, account_id: account.id, author_id: agent.id) }

  before { create(:portal_member, user: agent, portal: portal) }

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
            slug: 'my-title',
            content: 'This is my content.',
            status: :published,
            author_id: agent.id,
            position: 3
          }
        }
        post "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles",
             params: article_params,
             headers: agent.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['payload']['title']).to eql('MyTitle')
        expect(json_response['payload']['status']).to eql('draft')
        expect(json_response['payload']['position']).to be(3)
      end

      it 'creates article even if category is not provided' do
        article_params = {
          article: {
            category_id: nil,
            description: 'test description',
            title: 'MyTitle',
            slug: 'my-title',
            content: 'This is my content.',
            status: :published,
            author_id: agent.id,
            position: 3
          }
        }
        post "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles",
             params: article_params,
             headers: agent.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['payload']['title']).to eql('MyTitle')
        expect(json_response['payload']['status']).to eql('draft')
        expect(json_response['payload']['position']).to be(3)
      end

      it 'associate to the root article' do
        root_article = create(:article, category: category, slug: 'root-article', portal: portal, account_id: account.id, author_id: agent.id,
                                        associated_article_id: nil)
        parent_article = create(:article, category: category, slug: 'parent-article', portal: portal, account_id: account.id, author_id: agent.id,
                                          associated_article_id: root_article.id)

        article_params = {
          article: {
            category_id: category.id,
            description: 'test description',
            title: 'MyTitle',
            slug: 'MyTitle',
            content: 'This is my content.',
            status: :published,
            author_id: agent.id,
            associated_article_id: parent_article.id
          }
        }
        post "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles",
             params: article_params,
             headers: agent.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['payload']['title']).to eql('MyTitle')

        category = Article.find(json_response['payload']['id'])
        expect(category.associated_article_id).to eql(root_article.id)
      end

      it 'associate to the current parent article' do
        parent_article = create(:article, category: category, portal: portal, account_id: account.id, author_id: agent.id, associated_article_id: nil)

        article_params = {
          article: {
            category_id: category.id,
            description: 'test description',
            title: 'MyTitle',
            slug: 'MyTitle',
            content: 'This is my content.',
            status: :published,
            author_id: agent.id,
            associated_article_id: parent_article.id
          }
        }
        post "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles",
             params: article_params,
             headers: agent.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['payload']['title']).to eql('MyTitle')

        category = Article.find(json_response['payload']['id'])
        expect(category.associated_article_id).to eql(parent_article.id)
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
      it 'updates article' do
        article_params = {
          article: {
            title: 'MyTitle2',
            status: 'published',
            description: 'test_description',
            position: 5
          }
        }

        expect(article.title).not_to eql(article_params[:article][:title])

        put "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles/#{article.id}",
            params: article_params,
            headers: agent.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['payload']['title']).to eql(article_params[:article][:title])
        expect(json_response['payload']['status']).to eql(article_params[:article][:status])
        expect(json_response['payload']['position']).to eql(article_params[:article][:position])
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
        expect(deleted_article).to be_nil
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
        expect(article2.id).not_to be_nil

        get "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles",
            headers: agent.create_new_auth_token,
            params: {}
        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['payload'].count).to be 2
      end

      it 'get all articles with searched params' do
        article2 = create(:article, account_id: account.id, portal: portal, category: category, author_id: agent.id)
        expect(article2.id).not_to be_nil

        get "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles",
            headers: agent.create_new_auth_token,
            params: { category_slug: category.slug }
        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['payload'].count).to be 2
      end

      it 'get all articles with searched text query' do
        article2 = create(:article,
                          account_id: account.id,
                          portal: portal,
                          category: category,
                          author_id: agent.id,
                          content: 'this is some test and funny content')
        expect(article2.id).not_to be_nil

        get "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles",
            headers: agent.create_new_auth_token,
            params: { query: 'funny' }
        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['payload'].count).to be 1
        expect(json_response['meta']['all_articles_count']).to be 2
        expect(json_response['meta']['articles_count']).to be 1
        expect(json_response['meta']['mine_articles_count']).to be 1
      end
    end

    describe 'GET /api/v1/accounts/{account.id}/portals/{portal.slug}/articles/{article.id}' do
      it 'get article' do
        article2 = create(:article, account_id: account.id, portal: portal, category: category, author_id: agent.id)
        expect(article2.id).not_to be_nil

        get "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles/#{article2.id}",
            headers: agent.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = response.parsed_body

        expect(json_response['payload']['title']).to eq(article2.title)
        expect(json_response['payload']['id']).to eq(article2.id)
      end

      it 'get associated articles' do
        root_article = create(:article, category: category, portal: portal, account_id: account.id, author_id: agent.id, associated_article_id: nil)
        child_article_1 = create(:article, slug: 'child-1', category: category, portal: portal, account_id: account.id, author_id: agent.id,
                                           associated_article_id: root_article.id)
        child_article_2 = create(:article, slug: 'child-2', category: category, portal: portal, account_id: account.id, author_id: agent.id,
                                           associated_article_id: root_article.id)

        get "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles/#{root_article.id}",
            headers: agent.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = response.parsed_body

        expect(json_response['payload']['associated_articles'].length).to eq(2)
        associated_articles_ids = json_response['payload']['associated_articles'].pluck('id')
        expect(associated_articles_ids).to contain_exactly(child_article_1.id, child_article_2.id)
        expect(json_response['payload']['id']).to eq(root_article.id)
      end
    end
  end
end
