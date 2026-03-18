require 'rails_helper'

RSpec.describe 'Enterprise Billing APIs', type: :request do
  let(:account) { create(:account) }
  let!(:admin) { create(:user, account: account, role: :administrator) }
  let!(:agent) { create(:user, account: account, role: :agent) }

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

  describe 'GET /enterprise/api/v1/accounts/{account.id}/limits' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/enterprise/api/v1/accounts/#{account.id}/limits", as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      before do
        InstallationConfig.where(name: 'DEPLOYMENT_ENV').first_or_create(value: 'cloud')
        InstallationConfig.where(name: 'CHATWOOT_CLOUD_PLANS').first_or_create(value: [{ 'name': 'Hacker' }])
      end

      context 'when it is an agent' do
        it 'returns unauthorized' do
          get "/enterprise/api/v1/accounts/#{account.id}/limits",
              headers: agent.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)
          expect(json_response['id']).to eq(account.id)
          expect(json_response['limits']).to eq(
            {
              'conversation' => {
                'allowed' => 500,
                'consumed' => 0
              },
              'non_web_inboxes' => {
                'allowed' => 0,
                'consumed' => 0
              },
              'agents' => {
                'allowed' => 2,
                'consumed' => 2
              }
            }
          )
        end
      end

      context 'when it is an admin' do
        before do
          create(:conversation, account: account)
          create(:channel_api, account: account)
          InstallationConfig.where(name: 'DEPLOYMENT_ENV').first_or_create(value: 'cloud')
          InstallationConfig.where(name: 'CHATWOOT_CLOUD_PLANS').first_or_create(value: [{ 'name': 'Hacker' }])
        end

        it 'returns the limits if the plan is default' do
          account.update!(custom_attributes: { plan_name: 'Hacker' })
          get "/enterprise/api/v1/accounts/#{account.id}/limits",
              headers: admin.create_new_auth_token,
              as: :json

          expected_response = {
            'id' => account.id,
            'limits' => {
              'conversation' => {
                'allowed' => 500,
                'consumed' => 1
              },
              'non_web_inboxes' => {
                'allowed' => 0,
                'consumed' => 1
              },
              'agents' => {
                'allowed' => 2,
                'consumed' => 2
              }
            }
          }

          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)).to eq(expected_response)
        end

        it 'returns nil if the plan is not default' do
          account.update!(custom_attributes: { plan_name: 'Startups' })
          get "/enterprise/api/v1/accounts/#{account.id}/limits",
              headers: admin.create_new_auth_token,
              as: :json

          expected_response = {
            'id' => account.id,
            'limits' => {
              'agents' => {
                'allowed' => account.usage_limits[:agents],
                'consumed' => account.users.count
              },
              'conversation' => {},
              'captain' => {
                'documents' => { 'consumed' => 0, 'current_available' => ChatwootApp.max_limit, 'total_count' => ChatwootApp.max_limit },
                'responses' => { 'consumed' => 0, 'current_available' => ChatwootApp.max_limit, 'total_count' => ChatwootApp.max_limit }
              },
              'non_web_inboxes' => {}
            }
          }

          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)).to eq(expected_response)
        end

        it 'returns limits if a plan is not configured' do
          get "/enterprise/api/v1/accounts/#{account.id}/limits",
              headers: admin.create_new_auth_token,
              as: :json

          expected_response = {
            'id' => account.id,
            'limits' => {
              'conversation' => {
                'allowed' => 500,
                'consumed' => 1
              },
              'non_web_inboxes' => {
                'allowed' => 0,
                'consumed' => 1
              },
              'agents' => {
                'allowed' => 2,
                'consumed' => 2
              }
            }
          }
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)).to eq(expected_response)
        end
      end
    end
  end

  describe 'POST /enterprise/api/v1/accounts/{account.id}/topup_checkout' do
    let(:stripe_customer_id) { 'cus_test123' }
    let(:invoice_settings) { Struct.new(:default_payment_method).new('pm_test123') }
    let(:stripe_customer) { Struct.new(:invoice_settings, :default_source).new(invoice_settings, nil) }
    let(:stripe_invoice) { Struct.new(:id).new('inv_test123') }

    before do
      create(:installation_config, name: 'CHATWOOT_CLOUD_PLANS', value: [
               { 'name' => 'Hacker', 'product_id' => ['prod_hacker'], 'price_ids' => ['price_hacker'] },
               { 'name' => 'Business', 'product_id' => ['prod_business'], 'price_ids' => ['price_business'] }
             ])
    end

    it 'returns unauthorized for unauthenticated user' do
      post "/enterprise/api/v1/accounts/#{account.id}/topup_checkout", as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns unauthorized for agent' do
      post "/enterprise/api/v1/accounts/#{account.id}/topup_checkout",
           headers: agent.create_new_auth_token,
           params: { credits: 1000 },
           as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when it is an admin' do
      before do
        account.update!(
          custom_attributes: { plan_name: 'Business', stripe_customer_id: stripe_customer_id },
          limits: { 'captain_responses' => 1000 }
        )
        allow(Stripe::Customer).to receive(:retrieve).with(stripe_customer_id).and_return(stripe_customer)
        allow(Stripe::Invoice).to receive(:create).and_return(stripe_invoice)
        allow(Stripe::InvoiceItem).to receive(:create)
        allow(Stripe::Invoice).to receive(:finalize_invoice)
        allow(Stripe::Invoice).to receive(:pay)
        allow(Stripe::Billing::CreditGrant).to receive(:create)
      end

      it 'successfully processes topup and returns correct response' do
        post "/enterprise/api/v1/accounts/#{account.id}/topup_checkout",
             headers: admin.create_new_auth_token,
             params: { credits: 1000 },
             as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['credits']).to eq(1000)
        expect(json_response['amount']).to eq(20.0)
        expect(json_response['limits']['captain_responses']).to eq(2000)
      end

      it 'returns error when credits parameter is missing' do
        post "/enterprise/api/v1/accounts/#{account.id}/topup_checkout",
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error for invalid credits amount' do
        post "/enterprise/api/v1/accounts/#{account.id}/topup_checkout",
             headers: admin.create_new_auth_token,
             params: { credits: 999 },
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'POST /enterprise/api/v1/accounts/{account.id}/toggle_deletion' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/enterprise/api/v1/accounts/#{account.id}/toggle_deletion", as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      context 'when it is an agent' do
        it 'returns unauthorized' do
          post "/enterprise/api/v1/accounts/#{account.id}/toggle_deletion",
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unauthorized)
        end
      end

      context 'when deployment environment is not cloud' do
        before do
          # Set deployment environment to something other than cloud
          InstallationConfig.where(name: 'DEPLOYMENT_ENV').first_or_create(value: 'self_hosted')
        end

        it 'returns not found' do
          post "/enterprise/api/v1/accounts/#{account.id}/toggle_deletion",
               headers: admin.create_new_auth_token,
               params: { action_type: 'delete' },
               as: :json

          expect(response).to have_http_status(:not_found)
          expect(JSON.parse(response.body)['error']).to eq('Not found')
        end
      end

      context 'when it is an admin' do
        before do
          # Create the installation config for cloud environment
          InstallationConfig.where(name: 'DEPLOYMENT_ENV').first_or_initialize.update!(value: 'cloud')
        end

        it 'marks the account for deletion when action is delete' do
          cancellation_service = instance_double(Enterprise::Billing::CancelCloudSubscriptionsService, perform: true)
          allow(Enterprise::Billing::CancelCloudSubscriptionsService).to receive(:new).with(account: account)
                                                                                      .and_return(cancellation_service)

          post "/enterprise/api/v1/accounts/#{account.id}/toggle_deletion",
               headers: admin.create_new_auth_token,
               params: { action_type: 'delete' },
               as: :json

          expect(response).to have_http_status(:ok)
          expect(account.reload.custom_attributes['marked_for_deletion_at']).to be_present
          expect(account.custom_attributes['marked_for_deletion_reason']).to eq('manual_deletion')
          expect(Enterprise::Billing::CancelCloudSubscriptionsService).to have_received(:new).with(account: account)
          expect(cancellation_service).to have_received(:perform)
        end

        it 'returns success even if stripe cancellation fails' do
          cancellation_service = instance_double(Enterprise::Billing::CancelCloudSubscriptionsService)
          allow(Enterprise::Billing::CancelCloudSubscriptionsService).to receive(:new).with(account: account)
                                                                                      .and_return(cancellation_service)
          allow(cancellation_service).to receive(:perform).and_raise(Stripe::APIError.new('stripe unavailable'))

          post "/enterprise/api/v1/accounts/#{account.id}/toggle_deletion",
               headers: admin.create_new_auth_token,
               params: { action_type: 'delete' },
               as: :json

          expect(response).to have_http_status(:ok)
          expect(account.reload.custom_attributes['marked_for_deletion_at']).to be_present
          expect(account.custom_attributes['marked_for_deletion_reason']).to eq('manual_deletion')
        end

        it 'unmarks the account for deletion when action is undelete' do
          # First mark the account for deletion
          account.update!(
            custom_attributes: {
              'marked_for_deletion_at' => 7.days.from_now.iso8601,
              'marked_for_deletion_reason' => 'manual_deletion'
            }
          )

          post "/enterprise/api/v1/accounts/#{account.id}/toggle_deletion",
               headers: admin.create_new_auth_token,
               params: { action_type: 'undelete' },
               as: :json

          expect(response).to have_http_status(:ok)
          expect(account.reload.custom_attributes['marked_for_deletion_at']).to be_nil
          expect(account.custom_attributes['marked_for_deletion_reason']).to be_nil
        end

        it 'returns error for invalid action' do
          post "/enterprise/api/v1/accounts/#{account.id}/toggle_deletion",
               headers: admin.create_new_auth_token,
               params: { action_type: 'invalid' },
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)['error']).to include('Invalid action_type')
        end

        it 'returns error when action parameter is missing' do
          post "/enterprise/api/v1/accounts/#{account.id}/toggle_deletion",
               headers: admin.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)['error']).to include('Invalid action_type')
        end
      end
    end
  end
end
