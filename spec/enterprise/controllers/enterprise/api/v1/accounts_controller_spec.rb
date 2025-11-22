require 'rails_helper'

RSpec.describe 'Enterprise Billing APIs', type: :request do
  let(:account) { create(:account) }
  let!(:admin) { create(:user, account: account, role: :administrator) }
  let!(:agent) { create(:user, account: account, role: :agent) }

  def update_installation_config(name, value)
    InstallationConfig.find_or_initialize_by(name: name).tap do |config|
      config.value = value
      config.save!
    end
  end

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
    before do
      allow_any_instance_of(Account).to receive(:feature_enabled?).and_return(false)
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/enterprise/api/v1/accounts/#{account.id}/limits", as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when deployment environment is cloud' do
      before do
        update_installation_config('DEPLOYMENT_ENV', 'cloud')
        update_installation_config('CHATWOOT_CLOUD_PLANS', [{ 'name': 'Hacker' }])
      end

      context 'when it is an agent' do
        it 'returns limits for default plan' do
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

    context 'when deployment environment is self hosted' do
      before do
        update_installation_config('DEPLOYMENT_ENV', 'self_hosted')
        account.update!(limits: { 'inboxes' => 5, 'agents' => 10 })
        create(:conversation, account: account)
        create(:channel_email, account: account)
      end

      it 'returns usage data for self-hosted installs' do
        get "/enterprise/api/v1/accounts/#{account.id}/limits",
            headers: admin.create_new_auth_token,
            as: :json

        json_response = JSON.parse(response.body)
        expect(json_response['limits']).to include(
          'conversation' => hash_including('allowed' => ChatwootApp.max_limit, 'consumed' => 1),
          'non_web_inboxes' => hash_including('allowed' => 5, 'consumed' => 1),
          'agents' => hash_including('allowed' => 10, 'consumed' => 2)
        )
        expect(json_response['limits']['captain']).to include('documents', 'responses')
      end
    end

    context 'when a custom provider is configured' do
      let(:provider_class) do
        Class.new do
          def initialize(account)
            @account = account
          end

          def limits
            { 'custom_limits' => @account.id }
          end
        end
      end

      before do
        stub_const('CustomLimitsProvider', provider_class)
        update_installation_config('DEPLOYMENT_ENV', 'self_hosted')
        @original_provider = ENV['SELF_HOSTED_LIMITS_PROVIDER']
        ENV['SELF_HOSTED_LIMITS_PROVIDER'] = 'CustomLimitsProvider'
      end

      after do
        ENV['SELF_HOSTED_LIMITS_PROVIDER'] = @original_provider
      end

      it 'delegates limit calculation to the provider' do
        get "/enterprise/api/v1/accounts/#{account.id}/limits",
            headers: admin.create_new_auth_token,
            as: :json

        json_response = JSON.parse(response.body)
        expect(json_response['limits']).to eq('custom_limits' => account.id)
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
          update_installation_config('DEPLOYMENT_ENV', 'self_hosted')
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
          update_installation_config('DEPLOYMENT_ENV', 'cloud')
        end

        it 'marks the account for deletion when action is delete' do
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
