require 'rails_helper'

RSpec.describe 'Enterprise Billing APIs', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }

  describe 'POST /enterprise/api/v1/accounts/{account.id}/subscription' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/enterprise/api/v1/accounts/#{account.id}/subscription", as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      context 'when it is an agent' do
        it 'returns unauthorized' do
          post "/enterprise/api/v1/accounts/#{account.id}/subscription",
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unauthorized)
        end
      end

      context 'when it is an admin' do
        it 'enqueues a job' do
          expect do
            post "/enterprise/api/v1/accounts/#{account.id}/subscription",
                 headers: admin.create_new_auth_token,
                 as: :json
          end.to have_enqueued_job(Enterprise::CreateStripeCustomerJob).with(account)
          expect(account.reload.custom_attributes).to eq({ 'is_creating_customer': true }.with_indifferent_access)
        end

        it 'does not enqueue a job if a job is already enqueued' do
          account.update!(custom_attributes: { is_creating_customer: true })

          expect do
            post "/enterprise/api/v1/accounts/#{account.id}/subscription",
                 headers: admin.create_new_auth_token,
                 as: :json
          end.not_to have_enqueued_job(Enterprise::CreateStripeCustomerJob).with(account)
        end

        it 'does not enqueues a job if customer id is present' do
          account.update!(custom_attributes: { 'stripe_customer_id': 'cus_random_string' })

          expect do
            post "/enterprise/api/v1/accounts/#{account.id}/subscription",
                 headers: admin.create_new_auth_token,
                 as: :json
          end.not_to have_enqueued_job(Enterprise::CreateStripeCustomerJob).with(account)
        end
      end
    end
  end

  describe 'POST /enterprise/api/v1/accounts/{account.id}/checkout' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/enterprise/api/v1/accounts/#{account.id}/checkout", as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      context 'when it is an agent' do
        it 'returns unauthorized' do
          post "/enterprise/api/v1/accounts/#{account.id}/checkout",
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unauthorized)
        end
      end

      context 'when it is an admin and the stripe customer id is not present' do
        it 'returns error' do
          post "/enterprise/api/v1/accounts/#{account.id}/checkout",
               headers: admin.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('Please subscribe to a plan before viewing the billing details')
        end
      end

      context 'when it is an admin and the stripe customer is present' do
        it 'calls create session' do
          account.update!(custom_attributes: { 'stripe_customer_id': 'cus_random_string' })

          create_session_service = double
          allow(Enterprise::Billing::CreateSessionService).to receive(:new).and_return(create_session_service)
          allow(create_session_service).to receive(:create_session).and_return(create_session_service)
          allow(create_session_service).to receive(:url).and_return('https://billing.stripe.com/random_string')

          post "/enterprise/api/v1/accounts/#{account.id}/checkout",
               headers: admin.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)
          expect(json_response['redirect_url']).to eq('https://billing.stripe.com/random_string')
        end
      end
    end
  end
end
