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
    it 'Show portal and categories belonging to the portal' do
      get "/hc/#{portal.slug}/en"

      expect(response).to have_http_status(:success)
    end

    it 'Throws unauthorised error for unknown domain' do
      portal.update!(custom_domain: 'www.something.com')

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
end
