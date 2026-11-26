require 'rails_helper'

RSpec.describe 'Public Help Center search', type: :request do
  let(:account) { create(:account) }
  let(:author) { create(:user, account: account) }
  let(:portal) do
    create(:portal, account: account, custom_domain: 'www.example.com',
                    config: { allowed_locales: %w[en hr], default_locale: 'en', layout: layout })
  end

  result_labels = {
    1 => 'Pronađen je 1 rezultat',
    2 => 'Pronađeno je 2 rezultata',
    5 => 'Pronađeno je 5 rezultata',
    21 => 'Pronađen je 21 rezultat'
  }.freeze

  %w[classic documentation].each do |portal_layout|
    context "with the #{portal_layout} layout" do
      let(:layout) { portal_layout }

      it 'keeps the search term and result page in the canonical URL' do
        create_list(:article, 12, account: account, portal: portal, author: author, locale: 'hr', title: 'matchingcase & guide')

        get "/hc/#{portal.slug}/hr/search/", params: {
          query: ' matchingcase & guide ', page: 2, sort: 'views', per_page: 1,
          theme: 'dark', show_plain_layout: false, utm_source: 'newsletter', gclid: 'click', unrelated: 'ignored', host: 'wrong.example.com'
        }

        expect(response).to have_http_status(:success)
        page = Nokogiri::HTML5(response.body)
        canonical_urls = page.css('head link[rel="canonical"]').map { |link| link['href'] }
        expect(canonical_urls).to eq(["https://www.example.com/hc/#{portal.slug}/hr/search?page=2&query=matchingcase+%26+guide"])
        expect(page.css('h3').count { |heading| heading.text.strip == 'matchingcase & guide' }).to eq(2)
        content = page.at_css('main').text.squish

        get canonical_urls.first

        expect(response).to have_http_status(:success)
        expect(Nokogiri::HTML5(response.body).at_css('main').text.squish).to eq(content)
      end

      it 'uses the bare search route as canonical when the query is blank' do
        get "/hc/#{portal.slug}/hr/search", params: { query: '   ', utm_source: 'newsletter' }

        expect(response).to have_http_status(:success)
        expect(Nokogiri::HTML5(response.body).at_css('head link[rel="canonical"]')['href']).to eq("https://www.example.com/hc/#{portal.slug}/hr/search")
      end

      it 'does not canonicalize internal status-filtered results' do
        create(:article, account: account, portal: portal, author: author, locale: 'hr', title: 'matchingcase')

        get "/hc/#{portal.slug}/hr/search", params: { query: 'matchingcase', status: 'draft' }

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Nisu pronađeni rezultati')
        expect(Nokogiri::HTML5(response.body).css('head link[rel="canonical"]')).to be_empty
      end

      it 'omits canonical links when the portal is hidden from search' do
        portal.update!(config: portal.config.merge('disable_search_indexing' => true))

        get "/hc/#{portal.slug}/hr/search", params: { query: 'matchingcase' }

        expect(response).to have_http_status(:success)
        expect(response.headers['X-Robots-Tag']).to eq('noindex')
        expect(Nokogiri::HTML5(response.body).css('head link[rel="canonical"]')).to be_empty
      end

      it 'omits canonical links from plain search embeds' do
        get "/hc/#{portal.slug}/hr/search", params: { query: 'matchingcase', show_plain_layout: true }

        expect(response).to have_http_status(:success)
        expect(response.headers['X-Frame-Options']).to be_nil
        expect(Nokogiri::HTML5(response.body).css('head link[rel="canonical"]')).to be_empty
      end

      result_labels.each do |count, expected|
        it "renders the Croatian count for #{count} matching articles" do
          create_list(:article, count, account: account, portal: portal, author: author, locale: 'hr',
                                       title: 'matchingcase', content: 'Search count regression')

          get "/hc/#{portal.slug}/hr/search", params: { query: 'matchingcase' }

          expect(response).to have_http_status(:success)
          expect(response.body).to include(expected)
        end
      end

      it 'shows the empty result message for a nonmatching query' do
        create(:article, account: account, portal: portal, author: author, locale: 'hr', title: 'matchingcase')

        get "/hc/#{portal.slug}/hr/search", params: { query: 'missingcase' }

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Nisu pronađeni rezultati')
        expect(response.body).not_to include('Pronađen je')
      end
    end
  end
end
