require 'rails_helper'

RSpec.describe 'Public Articles API', type: :request do
  let!(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:portal) { create(:portal, slug: 'test-portal') }
  let!(:category) { create(:category, name: 'category', portal: portal, account_id: account.id, locale: 'en', slug: 'category_slug') }
  let!(:category_2) { create(:category, name: 'category', portal: portal, account_id: account.id, locale: 'es', slug: 'category_2_slug') }
  let!(:article) { create(:article, category: category, portal: portal, account_id: account.id, author_id: agent.id) }

  before do
    create(:article, category: category, portal: portal, account_id: account.id, author_id: agent.id)
    create(:article, category: category, portal: portal, account_id: account.id, author_id: agent.id, associated_article_id: article.id)
    create(:article, category: category_2, portal: portal, account_id: account.id, author_id: agent.id, associated_article_id: article.id)
    create(:article, category: category_2, portal: portal, account_id: account.id, author_id: agent.id)
  end

  describe 'GET /public/api/v1/portals/:portal_slug/articles' do
    it 'Fetch all articles in the portal' do
      get "/public/api/v1/portals/#{portal.slug}/articles"

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)

      expect(json_response['payload'].length).to eql portal.articles.count
    end

    it 'get all articles with searched text query' do
      article2 = create(:article,
                        account_id: account.id,
                        portal: portal,
                        category: category,
                        author_id: agent.id,
                        content: 'this is some test and funny content')
      expect(article2.id).not_to be nil

      get "/public/api/v1/portals/#{portal.slug}/articles",
          headers: agent.create_new_auth_token,
          params: { payload: { query: 'funny' } }
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['payload'].count).to be 1
    end
  end

  describe 'GET /public/api/v1/portals/:portal_slug/articles/:id' do
    it 'Fetch article with the id' do
      get "/public/api/v1/portals/#{portal.slug}/articles/#{article.id}"

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)

      expect(json_response['title']).to eql article.title
    end
  end
end
