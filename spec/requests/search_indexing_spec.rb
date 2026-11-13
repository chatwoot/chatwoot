require 'rails_helper'

RSpec.describe 'Search indexing', type: :request do
  let(:robots_directives) { Nokogiri::HTML(response.body).css('head meta[name="robots"]').map { |tag| tag['content'] } }

  before do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)
  end

  describe 'application login' do
    it 'prevents indexing on self-hosted installations even with the manifest disabled' do
      InstallationConfig.find_or_initialize_by(name: 'DISPLAY_MANIFEST').update!(value: false)

      get '/app/login'

      expect(response).to have_http_status(:ok)
      expect(robots_directives).to include('noindex')
      expect(response.body).not_to include('rel="manifest"')
    end

    it 'allows indexing on Cloud' do
      allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)

      get '/app/login'

      expect(response).to have_http_status(:ok)
      expect(robots_directives).not_to include('noindex')
      expect(response.headers['X-Robots-Tag']).to be_nil
    end
  end

  describe 'widget' do
    let(:web_widget) { create(:channel_widget) }

    [false, true].each do |cloud|
      it "prevents indexing on #{cloud ? 'Cloud' : 'self-hosted installations'}" do
        allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(cloud)

        get '/widget', params: { website_token: web_widget.website_token }

        expect(response).to have_http_status(:ok)
        expect(robots_directives).to include('noindex')
      end
    end
  end

  describe 'Super Admin' do
    before do
      allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
    end

    it 'prevents indexing of the sign-in page even on Cloud' do
      get '/super_admin/sign_in'

      expect(response).to have_http_status(:ok)
      expect(robots_directives).to include('noindex')
    end

    it 'prevents indexing of authenticated pages even on Cloud' do
      sign_in(create(:super_admin), scope: :super_admin)

      get '/super_admin/accounts'

      expect(response).to have_http_status(:ok)
      expect(robots_directives).to include('noindex')
    end
  end

  describe 'installation onboarding' do
    before { Redis::Alfred.set(Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING, true) }
    after { Redis::Alfred.delete(Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING) }

    it 'prevents indexing of the setup page reached from the homepage' do
      get '/'
      expect(response).to redirect_to('/installation/onboarding')

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(robots_directives).to include('noindex')
    end
  end

  describe 'public Help Center' do
    let(:web_widget) { create(:channel_widget) }
    let(:portal) { create(:portal, account: web_widget.account, channel_web_widget: web_widget, custom_domain: 'help.example.com') }

    %w[classic documentation].each do |layout|
      it "allows indexing of the custom-domain homepage with the #{layout} layout and an embedded widget" do
        portal.update!(config: { allowed_locales: ['en'], default_locale: 'en', layout: layout })

        with_modified_env FRONTEND_URL: 'https://app.example.com' do
          host! portal.custom_domain
          get '/'
        end

        expect(response).to have_http_status(:ok)
        expect(robots_directives).not_to include('noindex')
        expect(response.headers['X-Robots-Tag']).to be_nil
      end
    end
  end

  describe 'robots.txt' do
    it 'blocks widget crawling while leaving other pages crawlable' do
      get '/robots.txt'

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/plain')
      expect(response.body).to eq("User-agent: *\nDisallow: /widget\n")
    end
  end
end
