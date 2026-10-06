require 'rails_helper'

RSpec.describe 'Public Portal Access', type: :request do
  let!(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:portal) do
    create(:portal, account: account, slug: 'test-portal', config: { allowed_locales: %w[en] }, custom_domain: 'www.example.com')
  end
  let!(:category) { create(:category, portal: portal, account_id: account.id, locale: 'en', slug: 'category_slug') }
  let!(:article) { create(:article, category: category, portal: portal, account_id: account.id, author_id: agent.id) }
  let(:password) { 'opensesame1' }
  let(:html_headers) { { 'Accept' => 'text/html' } }

  before do
    ENV['HELPCENTER_URL'] = ENV.fetch('FRONTEND_URL', nil)
  end

  context 'when the portal is public' do
    it 'serves pages without a password' do
      get "/hc/#{portal.slug}/en", headers: html_headers

      expect(response).to have_http_status(:success)
      expect(response.headers['X-Robots-Tag']).to be_nil
    end

    it 'redirects unlock attempts to the portal home' do
      post "/hc/#{portal.slug}/unlock", params: { password: password }

      expect(response).to redirect_to("/hc/#{portal.slug}")
    end
  end

  context 'when the portal is password protected' do
    before { portal.update!(config: { visibility: 'password' }, password: password) }

    it 'shows the password page instead of the portal home' do
      get "/hc/#{portal.slug}/en", headers: html_headers

      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to include(I18n.t('public_portal.password.title'))
      expect(response.body).not_to include(category.name)
    end

    it 'shows the password page instead of an article' do
      get "/hc/#{portal.slug}/articles/#{article.slug}", headers: html_headers

      expect(response).to have_http_status(:unauthorized)
      expect(response.body).not_to include(article.title)
    end

    it 'does not reveal whether an article exists' do
      get "/hc/#{portal.slug}/articles/missing-article", headers: html_headers

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns an empty unauthorized response for non-HTML requests' do
      ["/hc/#{portal.slug}/en/articles.json", "/hc/#{portal.slug}/en/categories.json", "/hc/#{portal.slug}/sitemap.xml",
       "/hc/#{portal.slug}/articles/#{article.slug}.md", "/hc/#{portal.slug}/articles/#{article.slug}.png"].each do |path|
        get path

        expect(response).to have_http_status(:unauthorized), "expected #{path} to be unauthorized"
        expect(response.body).to be_empty
      end
    end

    it 'does not count article views while locked' do
      expect { get "/hc/#{portal.slug}/articles/#{article.slug}.png" }.not_to(change { article.reload.views })
    end

    it 'keeps protected pages out of search engines and caches' do
      get "/hc/#{portal.slug}/en", headers: html_headers

      expect(response.headers['X-Robots-Tag']).to eq('noindex, nofollow')
      expect(response.headers['Cache-Control']).to eq('no-store')
    end

    it 'rejects a wrong password' do
      post "/hc/#{portal.slug}/unlock", params: { password: 'wrong-password', return_to: "/hc/#{portal.slug}/en" }, headers: html_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(I18n.t('public_portal.password.invalid'))

      get "/hc/#{portal.slug}/en", headers: html_headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'unlocks the portal with the right password and returns to the requested page' do
      post "/hc/#{portal.slug}/unlock", params: { password: password, return_to: "/hc/#{portal.slug}/articles/#{article.slug}" }

      expect(response).to redirect_to("/hc/#{portal.slug}/articles/#{article.slug}")

      get "/hc/#{portal.slug}/articles/#{article.slug}", headers: html_headers
      expect(response).to have_http_status(:success)
      expect(response.body).to include(article.title)

      get "/hc/#{portal.slug}/en/articles.json"
      expect(response).to have_http_status(:success)
    end

    it 'ignores return paths outside the portal' do
      ['https://evil.example/phish', '//evil.example', '/app/login', "/hc/#{portal.slug}-other/en"].each do |return_to|
        post "/hc/#{portal.slug}/unlock", params: { password: password, return_to: return_to }

        expect(response).to redirect_to("/hc/#{portal.slug}")
      end
    end

    it 'signs visitors out when the password changes' do
      post "/hc/#{portal.slug}/unlock", params: { password: password }
      portal.update!(password: 'another-secret')

      get "/hc/#{portal.slug}/en", headers: html_headers

      expect(response).to have_http_status(:unauthorized)
    end

    it 'does not unlock other password protected portals' do
      other_portal = create(:portal, account: account, slug: 'other-portal', config: { visibility: 'password' }, password: password)
      post "/hc/#{portal.slug}/unlock", params: { password: password }

      get "/hc/#{other_portal.slug}/en", headers: html_headers

      expect(response).to have_http_status(:unauthorized)
    end

    it 'redirects the custom domain home page to the gated portal route' do
      get '/'

      expect(response).to redirect_to("http://www.example.com/hc/#{portal.slug}")
    end
  end
end
