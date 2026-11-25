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
      translation = create(:category, locale: 'es', portal: portal, associated_category_id: category.id)

      get "/hc/#{portal.slug}/#{category.locale}/categories/#{category.slug}"

      expect(response).to have_http_status(:success)
      expect(response.body).to include(%(value="/hc/#{portal.slug}/es/categories/#{translation.slug}"))
    end

    it 'links to the locale home when a translated category does not exist' do
      category = portal.categories.first

      get "/hc/#{portal.slug}/#{category.locale}/categories/#{category.slug}"

      expect(response).to have_http_status(:success)
      expect(response.body).to include(%(value="/hc/#{portal.slug}/es"))
    end

    it 'links to the original category and sibling translations from a translated category' do
      portal.update!(config: portal.config.merge('allowed_locales' => %w[en es fr]))
      category = portal.categories.first
      spanish_category = create(:category, locale: 'es', portal: portal, associated_category_id: category.id)
      french_category = create(:category, locale: 'fr', portal: portal, associated_category_id: category.id)

      get "/hc/#{portal.slug}/fr/categories/#{french_category.slug}"

      expect(response).to have_http_status(:success)
      expect(response.body).to include(
        %(value="/hc/#{portal.slug}/en/categories/#{category.slug}"),
        %(value="/hc/#{portal.slug}/es/categories/#{spanish_category.slug}")
      )
    end

    it 'links to the translated category in the documentation layout' do
      category = portal.categories.first
      translation = create(:category, locale: 'es', portal: portal, associated_category_id: category.id)
      portal.update!(config: portal.config.merge('layout' => 'documentation'))

      get "/hc/#{portal.slug}/#{category.locale}/categories/#{category.slug}"

      expect(response.body).to include(%(href="/hc/#{portal.slug}/es/categories/#{translation.slug}"))
    end

    it 'excludes translations from other portals' do
      category = portal.categories.first
      foreign_portal = create(:portal, config: { allowed_locales: %w[en es] })
      foreign_category = create(:category, portal: foreign_portal, locale: 'es', associated_category_id: category.id)

      get "/hc/#{portal.slug}/en/categories/#{category.slug}"

      expect(response).to have_http_status(:success)
      expect(response.body).to include(%(value="/hc/#{portal.slug}/es"))
      expect(response.body).not_to include("/hc/#{portal.slug}/es/categories/#{foreign_category.slug}")
    end

    it 'does not show the authors line when the only author has been deleted' do
      category = portal.categories.first
      article = create(:article, category: category, portal: portal, account_id: account.id)
      article.author.destroy!

      get "/hc/#{portal.slug}/#{category.locale}/categories/#{category.slug}"

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include("#{I18n.t('public_portal.common.by')} ")
    end
  end
end
