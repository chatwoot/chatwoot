require 'rails_helper'

RSpec.describe 'Public Categories API', type: :request do
  let!(:account) { create(:account) }
  let!(:portal) { create(:portal, slug: 'test-portal', custom_domain: 'www.example.com') }

  before do
    create(:category, slug: 'test-category-1', portal_id: portal.id, account_id: account.id)
    create(:category, slug: 'test-category-2', portal_id: portal.id, account_id: account.id)
    create(:category, slug: 'test-category-3', portal_id: portal.id, account_id: account.id)
  end

  describe 'GET /public/api/v1/portals/:portal_slug/categories' do
    it 'Fetch all categories in the portal' do
      get "/hc/#{portal.slug}/categories"

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)

      expect(json_response['payload'].length).to eql portal.categories.count
    end
  end

  describe 'GET /public/api/v1/portals/:portal_slug/categories/:slug' do
    it 'Fetch category with the slug' do
      category_locale = 'en'

      get "/hc/#{portal.slug}/categories/#{category_locale}"

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)

      expect(json_response['locale']).to eql category_locale
      expect(json_response['meta']['articles_count']).to be 0
    end
  end
end
