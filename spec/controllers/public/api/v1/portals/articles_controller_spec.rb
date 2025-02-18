require 'rails_helper'

RSpec.describe 'Public Articles API', type: :request do
  let!(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:portal) { create(:portal, slug: 'test-portal', config: { allowed_locales: %w[en es] }, custom_domain: 'www.example.com') }
  let!(:category) { create(:category, name: 'category', portal: portal, account_id: account.id, locale: 'en', slug: 'category_slug') }
  let!(:category_2) { create(:category, name: 'category', portal: portal, account_id: account.id, locale: 'es', slug: 'category_slug') }
  let!(:article) do
    create(:article, category: category, portal: portal, account_id: account.id, author_id: agent.id,
                     content: 'This is a *test* content with ^markdown^', views: 0)
  end

  before do
    ENV['HELPCENTER_URL'] = ENV.fetch('FRONTEND_URL', nil)
    create(:article, category: category, portal: portal, account_id: account.id, author_id: agent.id, views: 15)
    create(:article, category: category, portal: portal, account_id: account.id, author_id: agent.id, associated_article_id: article.id, views: 1)
    create(:article, category: category_2, portal: portal, account_id: account.id, author_id: agent.id, associated_article_id: article.id, views: 5)
    create(:article, category: category_2, portal: portal, account_id: account.id, author_id: agent.id, views: 4)
    create(:article, category: category_2, portal: portal, account_id: account.id, author_id: agent.id, status: :draft)
  end

  describe 'GET /public/api/v1/portals/:slug/articles' do
    it 'Fetch all articles in the portal' do
      get "/hc/#{portal.slug}/#{category.locale}/categories/#{category.slug}/articles"
      expect(response).to have_http_status(:success)
    end

    it 'Fetches only the published articles in the portal' do
      get "/hc/#{portal.slug}/#{category_2.locale}/categories/#{category.slug}/articles.json"
      expect(response).to have_http_status(:success)
      response_data = JSON.parse(response.body, symbolize_names: true)[:payload]
      expect(response_data.length).to eq(2)
    end

    it 'get all articles with searched text query' do
      article2 = create(:article,
                        account_id: account.id,
                        portal: portal,
                        category: category,
                        author_id: agent.id,
                        content: 'this is some test and funny content')
      expect(article2.id).not_to be_nil

      get "/hc/#{portal.slug}/#{category.locale}/categories/#{category.slug}/articles.json", params: { query: 'funny' }
      expect(response).to have_http_status(:success)
      response_data = JSON.parse(response.body, symbolize_names: true)[:payload]
      expect(response_data.length).to eq(1)
    end

    it 'get all popular articles if sort params is passed' do
      get "/hc/#{portal.slug}/#{category.locale}/articles.json", params: { sort: 'views' }

      expect(response).to have_http_status(:success)
      response_data = JSON.parse(response.body, symbolize_names: true)[:payload]
      expect(response_data.length).to eq(3)
      expect(response_data[0][:views]).to eq(15)
      expect(response_data[1][:views]).to eq(1)
      expect(response_data.last[:id]).to eq(article.id)
    end
  end

  describe 'GET /public/api/v1/portals/:slug/articles/:id' do
    it 'Fetch article with the id' do
      get "/hc/#{portal.slug}/articles/#{article.slug}"
      expect(response).to have_http_status(:success)
      expect(response.body).to include(ChatwootMarkdownRenderer.new(article.content).render_article)
      expect(article.reload.views).to eq 1
    end

    it 'does not increment the view count if the article is not published' do
      draft_article = create(:article, category: category, status: :draft, portal: portal, account_id: account.id, author_id: agent.id, views: 0)
      get "/hc/#{portal.slug}/articles/#{draft_article.slug}"
      expect(response).to have_http_status(:success)
      expect(draft_article.reload.views).to eq 0
    end

    it 'returns the article with the id with a different locale' do
      article_in_locale = create(:article, category: category_2, portal: portal, account_id: account.id, author_id: agent.id)
      get "/hc/#{portal.slug}/articles/#{article_in_locale.slug}"
      expect(response).to have_http_status(:success)
    end
  end
end
