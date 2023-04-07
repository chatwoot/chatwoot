require 'rails_helper'

RSpec.describe 'Public Articles API', type: :request do
  let!(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:portal) { create(:portal, slug: 'test-portal', config: { allowed_locales: %w[en es] }, custom_domain: 'www.example.com') }
  let!(:category) { create(:category, name: 'category', portal: portal, account_id: account.id, locale: 'en', slug: 'category_slug') }
  let!(:category_2) { create(:category, name: 'category', portal: portal, account_id: account.id, locale: 'es', slug: 'category_slug') }
  let!(:article) { create(:article, category: category, portal: portal, account_id: account.id, author_id: agent.id) }

  before do
    create(:article, category: category, portal: portal, account_id: account.id, author_id: agent.id)
    create(:article, category: category, portal: portal, account_id: account.id, author_id: agent.id, associated_article_id: article.id)
    create(:article, category: category_2, portal: portal, account_id: account.id, author_id: agent.id, associated_article_id: article.id)
    create(:article, category: category_2, portal: portal, account_id: account.id, author_id: agent.id)
  end

  describe 'GET /public/api/v1/portals/:slug/articles' do
    it 'Fetch all articles in the portal' do
      get "/hc/#{portal.slug}/#{category.locale}/#{category.slug}/articles"

      expect(response).to have_http_status(:success)
    end

    it 'get all articles with searched text query' do
      article2 = create(:article,
                        account_id: account.id,
                        portal: portal,
                        category: category,
                        author_id: agent.id,
                        content: 'this is some test and funny content')
      expect(article2.id).not_to be_nil

      get "/hc/#{portal.slug}/#{category.locale}/#{category.slug}/articles",
          headers: agent.create_new_auth_token,
          params: { query: 'funny' }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /public/api/v1/portals/:slug/articles/:id' do
    it 'Fetch article with the id' do
      get "/hc/#{portal.slug}/#{category.locale}/#{category.slug}/#{article.id}"
      expect(response).to have_http_status(:success)
      expect(article.reload.views).to eq 1
    end

    it 'returns the article with the id with a different locale' do
      article_in_locale = create(:article, category: category_2, portal: portal, account_id: account.id, author_id: agent.id)
      get "/hc/#{portal.slug}/#{category_2.locale}/#{category_2.slug}/#{article_in_locale.id}"
      expect(response).to have_http_status(:success)
    end
  end
end
