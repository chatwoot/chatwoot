require 'rails_helper'

RSpec.describe 'Public Help Center canonical URLs', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account) }
  let(:portal) do
    create(:portal, account: account, custom_domain: 'help.example.test',
                    config: { allowed_locales: %w[en pt_BR], default_locale: 'en', layout: layout })
  end
  let(:category) { create(:category, portal: portal, account: account, locale: 'pt_BR') }
  let!(:article) { create(:article, portal: portal, category: category, author: agent, status: :published, content: 'Guia publicado') }
  let(:home_path) { "/hc/#{portal.slug}/pt_BR" }
  let(:category_path) { "#{home_path}/categories/#{category.slug}" }
  let(:article_path) { "/hc/#{portal.slug}/articles/#{article.slug}" }

  def canonical_links
    Nokogiri::HTML5(response.body).css('head link[rel="canonical"]').map { |link| link['href'] }
  end

  around do |example|
    with_modified_env(FRONTEND_URL: 'http://app.example.test', HELPCENTER_URL: 'https://help-center.example.test') { example.run }
  end

  before { host! 'help.example.test' }

  routes = %i[home_path category_path article_path]
  preview_statuses = %i[draft published]

  %w[classic documentation].each do |portal_layout|
    context "with the #{portal_layout} layout" do
      let(:layout) { portal_layout }

      routes.each do |route|
        it "canonicalizes slash and tracking variants of #{route}" do
          path = public_send(route)

          get "#{path}/", params: { utm_source: 'newsletter', utm_campaign: 'launch', gclid: 'ad', fbclid: 'social', msclkid: 'click' }

          expect(response).to have_http_status(:ok)
          expect(canonical_links).to eq(["https://help.example.test#{path}"])
          original_content = Nokogiri::HTML5(response.body).at_css('main').text.squish

          get canonical_links.first

          expect(response).to have_http_status(:ok)
          expect(canonical_links).to eq(["https://help.example.test#{path}"])
          expect(Nokogiri::HTML5(response.body).at_css('main').text.squish).to eq(original_content)
        end

        it "preserves non-tracking query values on #{route}" do
          path = public_send(route)

          get path, params: { theme: 'dark', query: 'canais & contas', page: 2, utm_medium: 'email' }

          expect(response).to have_http_status(:ok)
          expect(canonical_links).to eq(["https://help.example.test#{path}?page=2&query=canais+%26+contas&theme=dark"])
        end

        it "keeps #{route} embeds free of canonical links" do
          get public_send(route), params: { show_plain_layout: true, theme: 'dark' }

          expect(response).to have_http_status(:ok)
          expect(response.headers['X-Frame-Options']).to be_nil
          expect(canonical_links).to be_empty
        end

        it "respects the portal search opt-out on #{route}" do
          portal.update!(config: portal.config.merge('disable_search_indexing' => true))

          get public_send(route)

          expect(response).to have_http_status(:ok)
          expect(response.headers['X-Robots-Tag']).to eq('noindex')
          expect(canonical_links).to be_empty
        end
      end

      it 'uses the custom domain even when requested through the shared host' do
        host! 'app.example.test'

        get article_path

        expect(response).to have_http_status(:ok)
        expect(canonical_links).to eq(["https://help.example.test#{article_path}"])
      end

      it 'uses the configured help center URL when there is no custom domain' do
        portal.update!(custom_domain: nil)
        host! 'app.example.test'

        with_modified_env(HELPCENTER_URL: 'https://help-center.example.test/') { get home_path }

        expect(response).to have_http_status(:ok)
        expect(canonical_links).to eq(["https://help-center.example.test#{home_path}"])
      end

      it 'falls back to the frontend URL when the help center URL is unset' do
        portal.update!(custom_domain: nil)
        host! 'app.example.test'

        with_modified_env(HELPCENTER_URL: nil) { get article_path }

        expect(response).to have_http_status(:ok)
        expect(canonical_links).to eq(["http://app.example.test#{article_path}"])
      end

      it 'keeps translations on their own article URLs' do
        original = create(:article, portal: portal, author: agent, locale: 'en', status: :published)
        article.update!(associated_article_id: original.id)

        get article_path
        expect(canonical_links).to eq(["https://help.example.test#{article_path}"])

        get "/hc/#{portal.slug}/articles/#{original.slug}"
        expect(canonical_links).to eq(["https://help.example.test/hc/#{portal.slug}/articles/#{original.slug}"])
      end

      it 'respects the article search opt-out' do
        article.update!(meta: { 'noindex' => true })

        get article_path

        expect(response).to have_http_status(:ok)
        expect(response.headers['X-Robots-Tag']).to eq('noindex')
        expect(canonical_links).to be_empty
      end

      it 'leaves draft locale indexing policy unchanged' do
        portal.update!(config: portal.config.merge('draft_locales' => ['pt_BR']))

        get home_path

        expect(response).to have_http_status(:ok)
        expect(response.headers['X-Robots-Tag']).to be_nil
        expect(canonical_links).to be_empty
      end

      preview_statuses.each do |status|
        it "does not canonicalize signed #{status} previews" do
          article.update!(status: status)

          get article_path, params: { preview_token: article.preview_token }

          expect(response).to have_http_status(:ok)
          expect(response.headers['X-Robots-Tag']).to eq('noindex')
          expect(canonical_links).to be_empty
        end
      end

      it 'keeps errors free of canonical links' do
        get "/hc/#{portal.slug}/pt_BR/categories/missing"

        expect(response).to have_http_status(:not_found)
        expect(canonical_links).to be_empty
      end

      it 'leaves search and article listing URLs unchanged' do
        ["#{home_path}/search", "#{home_path}/articles"].each do |path|
          get path, params: { query: 'Guia', page: 2 }

          expect(response).to have_http_status(:ok)
          expect(canonical_links).to be_empty
        end
      end
    end
  end
end
