require 'rails_helper'

RSpec.describe Public::Api::V1::PortalsController, type: :request do
  let!(:account) { create(:account) }
  let!(:agent) { create(:user, account: account, role: :agent) }
  let!(:portal) { create(:portal, slug: 'test-portal', account_id: account.id, custom_domain: 'www.example.com') }

  before do
    create(:portal, slug: 'test-portal-1', account_id: account.id)
    create(:portal, slug: 'test-portal-2', account_id: account.id)
    create_list(:article, 3, account: account, author: agent, portal: portal, status: :published)
    create_list(:article, 2, account: account, author: agent, portal: portal, status: :draft)
  end

  describe 'GET /public/api/v1/portals/{portal_slug}' do
    it 'redirects to the portal default locale when locale is not present' do
      get "/hc/#{portal.slug}"

      expect(response).to redirect_to("/hc/#{portal.slug}/#{portal.default_locale}")
    end

    describe 'canonical URL' do
      %w[classic documentation].each do |layout|
        context "with the #{layout} layout" do
          before do
            portal.update!(config: portal.config.merge('layout' => layout, 'allowed_locales' => %w[en pt_BR]))
          end

          it 'uses the custom domain and localized route without trailing slashes or query strings' do
            get "/hc/#{portal.slug}/pt_BR/", params: { query: 'canais', page: 2, theme: 'dark', utm_source: 'newsletter', unrelated: 'ignored' }

            expect(response).to have_http_status(:ok)
            page = Nokogiri::HTML5(response.body)
            canonical_urls = page.css('head link[rel="canonical"]').map { |link| link['href'] }
            expect(canonical_urls).to eq(["https://www.example.com/hc/#{portal.slug}/pt_BR"])
            content = page.at_css('main').text.squish

            get canonical_urls.first

            expect(response).to have_http_status(:ok)
            expect(Nokogiri::HTML5(response.body).at_css('main').text.squish).to eq(content)
          end

          it 'renders localized social metadata with og:url matching the canonical link' do
            portal.update!(config: portal.config.merge(
              'locale_translations' => { 'pt_BR' => { 'page_title' => 'Central de ajuda', 'header_text' => 'Como podemos ajudar?' } }
            ))

            get "/hc/#{portal.slug}/pt_BR"

            expect(response).to have_http_status(:ok)
            page_head = Nokogiri::HTML5(response.body).at_css('head')
            metadata = page_head.css('meta').to_h { |tag| [tag['property'] || tag['name'], tag['content']] }
            canonical_url = "https://www.example.com/hc/#{portal.slug}/pt_BR"
            expect(page_head.at_css('title').text).to eq('Central de ajuda')
            expect(page_head.at_css('link[rel="canonical"]')['href']).to eq(canonical_url)
            expect(metadata).to include(
              'og:title' => 'Central de ajuda', 'twitter:title' => 'Central de ajuda', 'og:type' => 'website',
              'description' => 'Como podemos ajudar?', 'og:description' => 'Como podemos ajudar?',
              'twitter:description' => 'Como podemos ajudar?', 'og:url' => canonical_url, 'twitter:url' => canonical_url
            )
          end

          it 'omits canonical links from plain embeds' do
            get "/hc/#{portal.slug}/pt_BR", params: { show_plain_layout: true, theme: 'dark' }

            expect(response).to have_http_status(:ok)
            expect(response.headers['X-Frame-Options']).to be_nil
            expect(Nokogiri::HTML5(response.body).css('head link[rel="canonical"]')).to be_empty
          end
        end
      end

      it 'uses the configured Help Center URL when there is no custom domain' do
        portal.update!(custom_domain: nil)

        with_modified_env(HELPCENTER_URL: 'https://www.example.com/') { get "/hc/#{portal.slug}/en" }

        expect(response).to have_http_status(:ok)
        expect(Nokogiri::HTML5(response.body).at_css('head link[rel="canonical"]')['href']).to eq("https://www.example.com/hc/#{portal.slug}/en")
      end

      it 'uses the frontend URL when the Help Center URL is unset' do
        portal.update!(custom_domain: nil)

        with_modified_env(HELPCENTER_URL: nil, FRONTEND_URL: 'https://www.example.com') { get "/hc/#{portal.slug}/en" }

        expect(response).to have_http_status(:ok)
        expect(Nokogiri::HTML5(response.body).at_css('head link[rel="canonical"]')['href']).to eq("https://www.example.com/hc/#{portal.slug}/en")
      end

      it 'uses the custom domain when requested through the shared host' do
        with_modified_env(HELPCENTER_URL: 'https://help.example.test') do
          host! 'help.example.test'
          get "/hc/#{portal.slug}/en"
        end

        expect(response).to have_http_status(:ok)
        expect(Nokogiri::HTML5(response.body).at_css('head link[rel="canonical"]')['href']).to eq("https://www.example.com/hc/#{portal.slug}/en")
      end
    end

    it 'shows portal categories with relative author avatars' do
      category = create(:category, portal: portal, account: account, locale: 'en')
      portal.articles.published.first.update!(category: category)
      agent.avatar.attach(fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png'))
      with_modified_env(FRONTEND_URL: 'http://localhost:3000', HELPCENTER_URL: 'http://help.example.test') do
        get "/hc/#{portal.slug}/en"

        expect(response).to have_http_status(:success)
        expect(Nokogiri::HTML5(response.body).css('img').map { |image| image['src'] }).to include(URI.parse(agent.avatar_url).request_uri)
      end
    end

    it 'does not set the session cookie' do
      previous = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true

      get "/hc/#{portal.slug}/en"

      expect(response.headers['Set-Cookie'].to_s).not_to include('_chatwoot_session')
    ensure
      ActionController::Base.allow_forgery_protection = previous
    end

    it 'Throws unauthorised error for unknown domain' do
      portal.update(custom_domain: 'www.something.com')

      get "/hc/#{portal.slug}/en"

      expect(response).to have_http_status(:unauthorized)
      json_response = response.parsed_body

      expect(json_response['error']).to eql "Domain: www.example.com is not registered with us. \
      Please send us an email at support@chatwoot.com with the custom domain name and account API key"
    end

    context 'when portal has a logo' do
      it 'includes the logo as favicon' do
        # Attach a test image to the portal
        file = Rails.root.join('spec/assets/sample.png').open
        portal.logo.attach(io: file, filename: 'sample.png', content_type: 'image/png')
        file.close

        get "/hc/#{portal.slug}/en"

        expect(response).to have_http_status(:success)
        expect(response.body).to include('<link rel="icon" href=')
      end

      it 'swaps to the dark mode logo in dark mode' do
        portal.logo.attach(io: Rails.root.join('spec/assets/sample.png').open, filename: 'sample.png', content_type: 'image/png')
        portal.dark_logo.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')

        get "/hc/#{portal.slug}/en"

        expect(response.body).to match(/sample\.png" class="[^"]*dark:hidden"/)
        expect(response.body).to match(/avatar\.png" class="[^"]*hidden dark:block"/)
      end
    end

    context 'when portal has no logo' do
      it 'does not include a favicon link' do
        # Ensure logo is not attached
        portal.logo.purge if portal.logo.attached?

        get "/hc/#{portal.slug}/en"

        expect(response).to have_http_status(:success)
        expect(response.body).not_to include('<link rel="icon" href=')
      end
    end

    it 'hides drafted locales from the public locale switcher' do
      portal.update!(config: { allowed_locales: %w[en es], draft_locales: ['es'], default_locale: 'en' })

      get "/hc/#{portal.slug}/en"

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include('value="es"')
      expect(response.body).not_to include('locale-switcher')
    end

    it 'allows direct access to drafted locale pages' do
      portal.update!(config: { allowed_locales: %w[en es], draft_locales: ['es'], default_locale: 'en' })

      get "/hc/#{portal.slug}/es"

      expect(response).to have_http_status(:success)
      expect(Nokogiri::HTML5(response.body).css('head link[rel="canonical"]')).to be_empty
    end

    it 'links the header logo to the current locale' do
      portal.update!(config: { allowed_locales: %w[en es], default_locale: 'en' })

      get "/hc/#{portal.slug}/es"

      expect(response.body).to include(%(href="/hc/#{portal.slug}/es"))
      expect(response.body).not_to include(%(href="/hc/#{portal.slug}/en"))
    end

    it 'shows the active drafted locale in the switcher state on direct locale access' do
      portal.update!(config: { allowed_locales: %w[en es fr], draft_locales: ['es'], default_locale: 'en' })

      get "/hc/#{portal.slug}/es"

      expect(response).to have_http_status(:success)

      document = Nokogiri::HTML(response.body)
      switchers = document.css('select.locale-switcher')

      expect(switchers).not_to be_empty

      switchers.each do |switcher|
        options = switcher.css('option')

        expect(options.map { |option| option['value'] }).to include(
          "/hc/#{portal.slug}/en",
          'es',
          "/hc/#{portal.slug}/fr"
        )
        expect(
          options.any? do |option|
            option['value'] == 'es' && option['selected'].present? && option['disabled'].present?
          end
        ).to be(true)
      end
    end
  end

  describe 'GET /public/api/v1/portals/{portal_slug}/{locale} recommended content' do
    let(:category_a) { create(:category, portal: portal, account: account, name: 'Getting Started', locale: 'en') }
    let(:category_b) { create(:category, portal: portal, account: account, name: 'Billing', locale: 'en') }
    let(:alpha) { create(:article, account: account, author: agent, portal: portal, locale: 'en', status: :published, title: 'Alpha Guide') }
    let(:beta) { create(:article, account: account, author: agent, portal: portal, locale: 'en', status: :published, title: 'Beta Guide') }
    let(:gamma) { create(:article, account: account, author: agent, portal: portal, locale: 'en', status: :published, title: 'Gamma Guide') }

    it 'renders recommended articles in the configured order' do
      portal.update!(config: { allowed_locales: %w[en], default_locale: 'en',
                               popular_content: { 'en' => { 'article_ids' => [gamma.id, alpha.id] } } })

      get "/hc/#{portal.slug}/en"

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Recommended articles')
      expect(response.body.index('Gamma Guide')).to be < response.body.index('Alpha Guide')
    end

    it 'drops draft and other-locale ids from the recommended articles' do
      draft = create(:article, account: account, author: agent, portal: portal, locale: 'en', status: :draft, title: 'Draft Secret')
      spanish = create(:article, account: account, author: agent, portal: portal, locale: 'es', status: :published, title: 'Spanish Only')
      portal.update!(config: { allowed_locales: %w[en es], default_locale: 'en',
                               popular_content: { 'en' => { 'article_ids' => [alpha.id, draft.id, spanish.id] } } })

      get "/hc/#{portal.slug}/en"

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Alpha Guide')
      expect(response.body).not_to include('Draft Secret')
      expect(response.body).not_to include('Spanish Only')
    end

    it 'does not leak one locale\'s recommendations into another' do
      portal.update!(config: { allowed_locales: %w[en es], default_locale: 'en',
                               popular_content: { 'es' => { 'article_ids' => [alpha.id] } } })

      get "/hc/#{portal.slug}/en"

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include('Recommended articles')
    end

    it 'renders recommended categories as hero pills in the configured order' do
      portal.update!(config: { allowed_locales: %w[en], default_locale: 'en',
                               popular_content: { 'en' => { 'category_ids' => [category_b.id, category_a.id] } } })

      get "/hc/#{portal.slug}/en"

      expect(response).to have_http_status(:success)
      expect(response.body).to include('recommended-pill')
      expect(response.body).to include('Getting Started', 'Billing')
      expect(response.body.index('Billing')).to be < response.body.index('Getting Started')
    end

    it 'falls back to featured articles when no recommendations are configured' do
      create_list(:article, 6, account: account, author: agent, portal: portal, locale: 'en', status: :published, category: category_a)

      get "/hc/#{portal.slug}/en"

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Featured Articles')
      expect(response.body).not_to include('Recommended articles')
    end

    it 'renders recommended articles in the documentation layout' do
      portal.update!(config: { allowed_locales: %w[en], default_locale: 'en', layout: 'documentation',
                               popular_content: { 'en' => { 'article_ids' => [alpha.id, beta.id] } } })

      get "/hc/#{portal.slug}/en"

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Recommended articles')
      expect(response.body).to include('Alpha Guide', 'Beta Guide')
    end
  end

  describe 'GET /public/api/v1/portals/{portal_slug}/sitemap' do
    context 'when custom_domain is present' do
      it 'returns a valid urlset sitemap with the correct namespace' do
        get "/hc/#{portal.slug}/sitemap.xml"

        expect(response).to have_http_status(:success)

        doc = Nokogiri::XML(response.body)
        expect(doc.errors).to be_empty

        expect(doc.root.name).to eq('urlset')
        expect(doc.root.namespace&.href).to eq('http://www.sitemaps.org/schemas/sitemap/0.9')
      end

      it 'contains valid article URLs for the portal' do
        get "/hc/#{portal.slug}/sitemap.xml"

        expect(response).to have_http_status(:success)

        doc = Nokogiri::XML(response.body)
        doc.remove_namespaces!

        # ensure we are NOT returning a sitemapindex
        expect(doc.xpath('//sitemapindex')).to be_empty

        links = doc.xpath('//url/loc').map(&:text)
        expect(links.length).to eq(3)

        expect(links).to all(
          match(%r{\Ahttps://www\.example\.com/hc/#{Regexp.escape(portal.slug)}/articles/\d+})
        )
      end
    end
  end

  describe 'search engine visibility' do
    it 'leaves articles hidden from search out of the sitemap' do
      portal.articles.published.first.update!(meta: { 'noindex' => true })

      get "/hc/#{portal.slug}/sitemap.xml"

      doc = Nokogiri::XML(response.body)
      doc.remove_namespaces!
      expect(doc.xpath('//url/loc').length).to eq(2)
    end

    it 'returns an empty sitemap and a noindex header when the portal is hidden' do
      portal.update!(config: portal.config.merge('disable_search_indexing' => true))

      get "/hc/#{portal.slug}/sitemap.xml"

      doc = Nokogiri::XML(response.body)
      doc.remove_namespaces!
      expect(doc.xpath('//url')).to be_empty
      expect(response.headers['X-Robots-Tag']).to eq('noindex')
    end

    it 'sends a noindex header on portal pages only when the portal is hidden' do
      get "/hc/#{portal.slug}/en"
      expect(response.headers['X-Robots-Tag']).to be_nil

      portal.update!(config: portal.config.merge('disable_search_indexing' => true))

      get "/hc/#{portal.slug}/en"
      expect(response.headers['X-Robots-Tag']).to eq('noindex')
      expect(Nokogiri::HTML5(response.body).css('head link[rel="canonical"]')).to be_empty
    end
  end
end
