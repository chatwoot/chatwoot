require 'rails_helper'

RSpec.describe 'Public Categories API', type: :request do
  let!(:account) { create(:account) }
  let!(:portal) do
    create(:portal, slug: 'test-portal', custom_domain: 'www.example.com', config: { allowed_locales: %w[en es] })
  end

  before do
    create(:category, slug: 'test-category-1', portal_id: portal.id, account_id: account.id)
    create(:category, slug: 'test-category-2', portal_id: portal.id, account_id: account.id)
    create(:category, slug: 'test-category-3', portal_id: portal.id, account_id: account.id)
  end

  describe 'GET /public/api/v1/portals/:portal_slug/categories' do
    it 'redirects to the locale home page' do
      category = portal.categories.first

      get "/hc/#{portal.slug}/#{category.locale}/categories"

      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to("/hc/#{portal.slug}/#{category.locale}")
    end
  end

  describe 'GET /public/api/v1/portals/:portal_slug/categories/:slug' do
    it 'Fetch category with the slug' do
      category = portal.categories.first

      get "/hc/#{portal.slug}/#{category.locale}/categories/#{category.slug}"

      expect(response).to have_http_status(:success)
    end

    it 'links to the matching translated category from the locale switcher' do
      category = portal.categories.first
      translated_category = create(:category, slug: 'translated-category', locale: 'es', portal: portal,
                                              account_id: account.id, associated_category_id: category.id)

      get "/hc/#{portal.slug}/#{category.locale}/categories/#{category.slug}"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("value=\"/hc/#{portal.slug}/es/categories/#{translated_category.slug}\"")
    end

    it 'links to the locale home when a translated category does not exist' do
      category = portal.categories.first

      get "/hc/#{portal.slug}/#{category.locale}/categories/#{category.slug}"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("value=\"/hc/#{portal.slug}/es\"")
    end

    it 'links to the most recently created category when multiple translations share a locale' do
      category = portal.categories.first
      create(:category, slug: 'older-translation', locale: 'es', portal: portal,
                        account_id: account.id, associated_category_id: category.id)
      latest_translation = create(:category, slug: 'latest-translation', locale: 'es', portal: portal,
                                             account_id: account.id, associated_category_id: category.id)

      get "/hc/#{portal.slug}/#{category.locale}/categories/#{category.slug}"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("value=\"/hc/#{portal.slug}/es/categories/#{latest_translation.slug}\"")
      expect(response.body).not_to include('/es/categories/older-translation')
    end

    it 'links to the translated category in the documentation layout' do
      category = portal.categories.first
      translated_category = create(:category, slug: 'translated-category', locale: 'es', portal: portal,
                                              account_id: account.id, associated_category_id: category.id)
      portal.update!(config: portal.config.merge('layout' => 'documentation'))

      get "/hc/#{portal.slug}/#{category.locale}/categories/#{category.slug}"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("href=\"/hc/#{portal.slug}/es/categories/#{translated_category.slug}\"")
    end
  end
end
