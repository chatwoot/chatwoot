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
