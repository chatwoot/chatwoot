require 'rails_helper'

RSpec.describe 'Catalog Stats API', type: :request do
  let!(:account) { create(:account) }

  describe 'GET /api/v1/accounts/{account.id}/catalog_stats' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/catalog_stats"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns aggregated stats' do
        create_list(:product, 3, account: account, stock: 10)
        create(:product, account: account, stock: 0)
        create(:order, :paid, account: account, total: 100.0)
        create(:order, :paid, account: account, total: 50.0)
        create(:order, account: account, status: :pending)
        create(:payment_link, :paid, account: account, amount: 75.0)
        create(:payment_link, account: account, status: :pending)

        get "/api/v1/accounts/#{account.id}/catalog_stats",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json = response.parsed_body

        expect(json['products']['total']).to eq(4)
        expect(json['products']['in_stock']).to eq(3)
        expect(json['products']['out_of_stock']).to eq(1)

        expect(json['orders']['total']).to eq(3)
        expect(json['orders']['paid']).to eq(2)
        expect(json['orders']['pending']).to eq(1)
        expect(json['orders']['total_revenue']).to eq(150.0)

        expect(json['payment_links']['total']).to eq(2)
        expect(json['payment_links']['paid']).to eq(1)
        expect(json['payment_links']['pending']).to eq(1)
        expect(json['payment_links']['total_revenue']).to eq(75.0)

        expect(json['currency']).to eq('SAR')
      end

      it 'returns correct currency from catalog settings' do
        AccountCatalogSettings.create!(account: account, enabled: true, currency: 'KWD')

        get "/api/v1/accounts/#{account.id}/catalog_stats",
            headers: agent.create_new_auth_token,
            as: :json

        json = response.parsed_body
        expect(json['currency']).to eq('KWD')
      end

      it 'returns zero stats when no data exists' do
        get "/api/v1/accounts/#{account.id}/catalog_stats",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json = response.parsed_body

        expect(json['products']['total']).to eq(0)
        expect(json['orders']['total']).to eq(0)
        expect(json['payment_links']['total']).to eq(0)
        expect(json['orders']['total_revenue']).to eq(0.0)
      end
    end
  end
end
