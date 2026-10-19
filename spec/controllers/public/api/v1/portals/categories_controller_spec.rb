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

    it 'links to the root category when the current translation has a nested association' do
      portal.update!(config: portal.config.merge('allowed_locales' => %w[en es fr]))
      category = portal.categories.first
      parent_translation = create(:category, slug: 'parent-translation', locale: 'es', portal: portal,
                                             account_id: account.id, associated_category_id: category.id)
      nested_translation = create(:category, slug: 'nested-translation', locale: 'fr', portal: portal,
                                             account_id: account.id, associated_category_id: parent_translation.id)

      get "/hc/#{portal.slug}/#{nested_translation.locale}/categories/#{nested_translation.slug}"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("value=\"/hc/#{portal.slug}/#{category.locale}/categories/#{category.slug}\"")
      expect(response.body).to include("value=\"/hc/#{portal.slug}/es/categories/#{parent_translation.slug}\"")

      get "/hc/#{portal.slug}/#{category.locale}/categories/#{category.slug}"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("value=\"/hc/#{portal.slug}/#{nested_translation.locale}/categories/#{nested_translation.slug}\"")
    end

    it 'renders a category with a dangling translation association' do
      category = portal.categories.first
      category.update!(associated_category_id: Category.maximum(:id).to_i + 1)

      get "/hc/#{portal.slug}/#{category.locale}/categories/#{category.slug}"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("value=\"/hc/#{portal.slug}/#{category.locale}/categories/#{category.slug}\"")
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

    it 'does not follow translation parents outside the portal' do
      category = portal.categories.first
      create(:category, slug: 'unrelated-translation', locale: 'es', portal: portal, associated_category_id: category.id)
      foreign_parent = create(:category, associated_category_id: category.id)
      source_category = create(:category, slug: 'source-category', portal: portal, associated_category_id: foreign_parent.id)

      get "/hc/#{portal.slug}/en/categories/#{source_category.slug}"

      expect(response).to have_http_status(:success)
      switchers = Nokogiri::HTML(response.body).css('select.locale-switcher')
      expect(switchers.size).to eq(2)
      switchers.each do |switcher|
        expect(switcher.css('option').map { |option| option['value'] }).to include("/hc/#{portal.slug}/es")
      end
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
