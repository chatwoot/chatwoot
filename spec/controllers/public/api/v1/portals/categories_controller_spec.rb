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

    describe 'page metadata' do
      let(:localized_category) do
        create(:category, portal: portal, locale: 'es', name: 'Configuración & canales', description: 'Guía de configuración.')
      end

      %w[classic documentation].each do |layout|
        it "uses the localized category title and description in the #{layout} layout" do
          portal.update!(config: portal.config.merge('layout' => layout,
                                                     'locale_translations' => { 'es' => { 'page_title' => 'Centro de ayuda' } }))
          create(:installation_config, name: 'OG_IMAGE_CDN_URL', value: 'https://cdn.example.com')

          get "/hc/#{portal.slug}/#{localized_category.locale}/categories/#{localized_category.slug}"

          expect(response).to have_http_status(:ok)
          page_head = Nokogiri::HTML5(response.body).at_css('head')
          metadata = page_head.css('meta').to_h { |tag| [tag['property'] || tag['name'], tag['content']] }
          expected_title = 'Configuración & canales | Centro de ayuda'
          expect(page_head.at_css('title').text).to eq(expected_title)
          expect(metadata).to include(
            'og:title' => expected_title, 'twitter:title' => expected_title, 'og:type' => 'website',
            'description' => localized_category.description, 'og:description' => localized_category.description,
            'twitter:description' => localized_category.description
          )
          expect(metadata['og:image']).to start_with('https://cdn.example.com/og?')
          expect(metadata['twitter:image']).to eq(metadata['og:image'])
        end
      end
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
      foreign_category = create(:category, portal: foreign_portal, locale: 'es')
      foreign_category.update_column(:associated_category_id, category.id) # rubocop:disable Rails/SkipsModelValidations

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
