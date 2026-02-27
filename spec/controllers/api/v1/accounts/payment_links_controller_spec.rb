require 'rails_helper'

RSpec.describe 'Payment Links API', type: :request do
  let!(:account) { create(:account) }
  let!(:agent) { create(:user, account: account, role: :agent) }

  describe 'GET /api/v1/accounts/{account.id}/payment_links' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/payment_links"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let!(:payment_links) { create_list(:payment_link, 3, account: account) }

      it 'returns all payment links with pagination meta' do
        get "/api/v1/accounts/#{account.id}/payment_links",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json = response.parsed_body
        expect(json['payload'].length).to eq(3)
        expect(json['meta']['count']).to eq(3)
        expect(json['meta']['current_page']).to eq(1)
      end

      it 'paginates results' do
        create_list(:payment_link, 16, account: account)

        get "/api/v1/accounts/#{account.id}/payment_links",
            params: { page: 1 },
            headers: agent.create_new_auth_token,
            as: :json

        json = response.parsed_body
        expect(json['payload'].length).to eq(15)
        expect(json['meta']['count']).to eq(19) # 3 + 16

        get "/api/v1/accounts/#{account.id}/payment_links",
            params: { page: 2 },
            headers: agent.create_new_auth_token,
            as: :json

        json = response.parsed_body
        expect(json['payload'].length).to eq(4)
      end

      it 'filters by status' do
        create(:payment_link, :paid, account: account)

        get "/api/v1/accounts/#{account.id}/payment_links",
            params: { status: 'paid' },
            headers: agent.create_new_auth_token,
            as: :json

        json = response.parsed_body
        expect(json['payload']).to all(include('status' => 'paid'))
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/payment_links/:id' do
    let!(:payment_link) { create(:payment_link, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/payment_links/#{payment_link.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns the payment link' do
        get "/api/v1/accounts/#{account.id}/payment_links/#{payment_link.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json = response.parsed_body
        expect(json['id']).to eq(payment_link.id)
        expect(json['external_payment_id']).to eq(payment_link.external_payment_id)
        expect(json['amount'].to_f).to eq(payment_link.amount.to_f)
        expect(json['status']).to eq(payment_link.status)
        expect(json['contact']).to be_present
        expect(json['conversation']).to be_present
      end

      it 'returns 404 for non-existent payment link' do
        get "/api/v1/accounts/#{account.id}/payment_links/0",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/payment_links' do
    let!(:conversation) { create(:conversation, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/payment_links",
             params: { conversation_id: conversation.id, amount: 50, currency: 'KWD' }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      before do
        AccountPayzahSettings.create!(account: account, enabled: true, api_key: 'test_api_key')

        allow_any_instance_of(Payzah::CreatePaymentLinkService).to receive(:perform).and_return(
          {
            'transit_url' => 'https://example.com/pay/123',
            'PaymentID' => 'PAY123'
          }
        )
      end

      it 'creates a payment link for a conversation' do
        params = { conversation_id: conversation.id, amount: 50.00, currency: 'KWD' }

        expect do
          post "/api/v1/accounts/#{account.id}/payment_links",
               params: params,
               headers: agent.create_new_auth_token,
               as: :json
        end.to change(PaymentLink, :count).by(1)

        expect(response).to have_http_status(:created)
        json = response.parsed_body
        expect(json['amount'].to_f).to eq(50.0)
        expect(json['currency']).to eq('KWD')
        expect(json['payment_url']).to eq('https://example.com/pay/123')
      end

      it 'returns not found for invalid conversation' do
        params = { conversation_id: 0, amount: 50, currency: 'KWD' }

        post "/api/v1/accounts/#{account.id}/payment_links",
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/payment_links/search' do
    let!(:payment_link) { create(:payment_link, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/payment_links/search", params: { q: 'test' }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'searches by external_payment_id' do
        get "/api/v1/accounts/#{account.id}/payment_links/search",
            params: { q: payment_link.external_payment_id, sort: '-created_at' },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json = response.parsed_body
        expect(json['payload'].length).to eq(1)
        expect(json['payload'][0]['id']).to eq(payment_link.id)
      end

      it 'returns no content when q is missing' do
        get "/api/v1/accounts/#{account.id}/payment_links/search",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:no_content)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/payment_links/:id/cancel' do
    context 'when it is an unauthenticated user' do
      let!(:payment_link) { create(:payment_link, account: account) }

      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/payment_links/#{payment_link.id}/cancel"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'cancels a pending payment link' do
        payment_link = create(:payment_link, account: account, status: :pending)

        patch "/api/v1/accounts/#{account.id}/payment_links/#{payment_link.id}/cancel",
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)
        json = response.parsed_body
        expect(json['status']).to eq('cancelled')
        expect(payment_link.reload.status).to eq('cancelled')
      end

      it 'cancels an initiated payment link' do
        payment_link = create(:payment_link, :initiated, account: account)

        patch "/api/v1/accounts/#{account.id}/payment_links/#{payment_link.id}/cancel",
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)
        expect(payment_link.reload.status).to eq('cancelled')
      end

      it 'returns error when cancelling a paid payment link' do
        payment_link = create(:payment_link, :paid, account: account)

        patch "/api/v1/accounts/#{account.id}/payment_links/#{payment_link.id}/cancel",
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = response.parsed_body
        expect(json['error']).to include('paid')
      end

      it 'returns 404 for non-existent payment link' do
        patch "/api/v1/accounts/#{account.id}/payment_links/0/cancel",
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
