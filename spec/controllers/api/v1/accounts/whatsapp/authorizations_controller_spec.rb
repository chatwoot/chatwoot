require 'rails_helper'
require_relative '../../../../../../lib/custom_exceptions/whatsapp_rate_limit_error'

RSpec.describe 'WhatsApp Authorization API', type: :request do
  let(:account) { create(:account) }

  describe 'POST /api/v1/accounts/{account.id}/whatsapp/authorization' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/whatsapp/authorization"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }

      context 'when authenticated user makes request' do
        it 'returns unprocessable entity when code is missing' do
          post "/api/v1/accounts/#{account.id}/whatsapp/authorization",
               params: {
                 business_id: 'test_business_id',
                 waba_id: 'test_waba_id'
               },
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body['error']).to include('code')
        end

        it 'returns unprocessable entity when business_id is missing' do
          post "/api/v1/accounts/#{account.id}/whatsapp/authorization",
               params: {
                 code: 'test_code',
                 waba_id: 'test_waba_id'
               },
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body['error']).to include('business_id')
        end

        it 'returns unprocessable entity when waba_id is missing' do
          post "/api/v1/accounts/#{account.id}/whatsapp/authorization",
               params: {
                 code: 'test_code',
                 business_id: 'test_business_id'
               },
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body['error']).to include('waba_id')
        end

        it 'creates whatsapp channel successfully' do
          whatsapp_channel = create(:channel_whatsapp, account: account, validate_provider_config: false, sync_templates: false)
          inbox = create(:inbox, account: account, channel: whatsapp_channel)
          embedded_signup_service = instance_double(Whatsapp::EmbeddedSignupService)

          allow(Whatsapp::EmbeddedSignupService).to receive(:new).and_return(embedded_signup_service)
          allow(embedded_signup_service).to receive(:perform).and_return(whatsapp_channel)
          allow(whatsapp_channel).to receive(:inbox).and_return(inbox)

          # Stub webhook setup service to prevent HTTP calls
          webhook_service = instance_double(Whatsapp::WebhookSetupService)
          allow(Whatsapp::WebhookSetupService).to receive(:new).and_return(webhook_service)
          allow(webhook_service).to receive(:perform)

          post "/api/v1/accounts/#{account.id}/whatsapp/authorization",
               params: {
                 code: 'test_code',
                 business_id: 'test_business_id',
                 waba_id: 'test_waba_id',
                 phone_number_id: 'test_phone_id'
               },
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:success)
          response_data = response.parsed_body
          expect(response_data['success']).to be true
          expect(response_data['id']).to eq(inbox.id)
          expect(response_data['name']).to eq(inbox.name)
          expect(response_data['channel_type']).to eq('whatsapp')
        end

        it 'calls the embedded signup service with correct parameters' do
          whatsapp_channel = create(:channel_whatsapp, account: account, validate_provider_config: false, sync_templates: false)
          inbox = create(:inbox, account: account, channel: whatsapp_channel)
          embedded_signup_service = instance_double(Whatsapp::EmbeddedSignupService)

          expect(Whatsapp::EmbeddedSignupService).to receive(:new).with(
            account: account,
            params: {
              code: 'test_code',
              business_id: 'test_business_id',
              waba_id: 'test_waba_id',
              phone_number_id: 'test_phone_id'
            },
            inbox_id: nil
          ).and_return(embedded_signup_service)

          allow(embedded_signup_service).to receive(:perform).and_return(whatsapp_channel)
          allow(whatsapp_channel).to receive(:inbox).and_return(inbox)
          allow(Whatsapp::WebhookSetupService).to receive(:new).and_return(instance_double(Whatsapp::WebhookSetupService, perform: true))

          post "/api/v1/accounts/#{account.id}/whatsapp/authorization",
               params: {
                 code: 'test_code',
                 business_id: 'test_business_id',
                 waba_id: 'test_waba_id',
                 phone_number_id: 'test_phone_id'
               },
               headers: agent.create_new_auth_token,
               as: :json
        end

        it 'accepts phone_number_id as optional parameter' do
          whatsapp_channel = create(:channel_whatsapp, account: account, validate_provider_config: false, sync_templates: false)
          inbox = create(:inbox, account: account, channel: whatsapp_channel)
          embedded_signup_service = instance_double(Whatsapp::EmbeddedSignupService)

          expect(Whatsapp::EmbeddedSignupService).to receive(:new).with(
            account: account,
            params: {
              code: 'test_code',
              business_id: 'test_business_id',
              waba_id: 'test_waba_id'
            },
            inbox_id: nil
          ).and_return(embedded_signup_service)

          allow(embedded_signup_service).to receive(:perform).and_return(whatsapp_channel)
          allow(whatsapp_channel).to receive(:inbox).and_return(inbox)
          allow(Whatsapp::WebhookSetupService).to receive(:new).and_return(instance_double(Whatsapp::WebhookSetupService, perform: true))

          post "/api/v1/accounts/#{account.id}/whatsapp/authorization",
               params: {
                 code: 'test_code',
                 business_id: 'test_business_id',
                 waba_id: 'test_waba_id'
               },
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:success)
        end

        it 'returns unprocessable entity when service fails' do
          allow(Whatsapp::EmbeddedSignupService).to receive(:new).and_raise(StandardError, 'Service error')

          post "/api/v1/accounts/#{account.id}/whatsapp/authorization",
               params: {
                 code: 'test_code',
                 business_id: 'test_business_id',
                 waba_id: 'test_waba_id'
               },
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          response_data = response.parsed_body
          expect(response_data['success']).to be false
          expect(response_data['error']).to eq('Service error')
        end

        it 'logs error when service fails' do
          allow(Whatsapp::EmbeddedSignupService).to receive(:new).and_raise(StandardError, 'Service error')

          expect(Rails.logger).to receive(:error).with(/\[WHATSAPP AUTHORIZATION\] Embedded signup error: Service error/)
          expect(Rails.logger).to receive(:error).with(/authorizations_controller/)

          post "/api/v1/accounts/#{account.id}/whatsapp/authorization",
               params: {
                 code: 'test_code',
                 business_id: 'test_business_id',
                 waba_id: 'test_waba_id'
               },
               headers: agent.create_new_auth_token,
               as: :json
        end

        it 'handles token exchange errors' do
          allow(Whatsapp::EmbeddedSignupService).to receive(:new)
            .and_raise(StandardError, 'Invalid authorization code')

          post "/api/v1/accounts/#{account.id}/whatsapp/authorization",
               params: {
                 code: 'invalid_code',
                 business_id: 'test_business_id',
                 waba_id: 'test_waba_id'
               },
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body['error']).to eq('Invalid authorization code')
        end

        it 'handles channel already exists error' do
          allow(Whatsapp::EmbeddedSignupService).to receive(:new)
            .and_raise(StandardError, 'Channel already exists')

          post "/api/v1/accounts/#{account.id}/whatsapp/authorization",
               params: {
                 code: 'test_code',
                 business_id: 'test_business_id',
                 waba_id: 'test_waba_id'
               },
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body['error']).to eq('Channel already exists')
        end
      end

      context 'when user is not authorized for the account' do
        let(:other_account) { create(:account) }

        it 'returns unauthorized' do
          post "/api/v1/accounts/#{other_account.id}/whatsapp/authorization",
               params: {
                 code: 'test_code',
                 business_id: 'test_business_id',
                 waba_id: 'test_waba_id'
               },
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unauthorized)
        end
      end

      context 'when user is an administrator' do
        it 'allows channel creation' do
          embedded_signup_service = instance_double(Whatsapp::EmbeddedSignupService)
          whatsapp_channel = create(:channel_whatsapp, account: account, validate_provider_config: false, sync_templates: false)
          inbox = create(:inbox, account: account, channel: whatsapp_channel)

          allow(Whatsapp::EmbeddedSignupService).to receive(:new).and_return(embedded_signup_service)
          allow(embedded_signup_service).to receive(:perform).and_return(whatsapp_channel)
          allow(whatsapp_channel).to receive(:inbox).and_return(inbox)

          # Stub webhook setup service
          webhook_service = instance_double(Whatsapp::WebhookSetupService)
          allow(Whatsapp::WebhookSetupService).to receive(:new).and_return(webhook_service)
          allow(webhook_service).to receive(:perform)

          post "/api/v1/accounts/#{account.id}/whatsapp/authorization",
               params: {
                 code: 'test_code',
                 business_id: 'test_business_id',
                 waba_id: 'test_waba_id'
               },
               headers: administrator.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:success)
        end
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/whatsapp/authorization with inbox_id (reauthorization)' do
    let(:whatsapp_channel) do
      channel = build(:channel_whatsapp, account: account, provider: 'whatsapp_cloud',
                                         provider_config: {
                                           'api_key' => 'test_token',
                                           'phone_number_id' => '123456',
                                           'business_account_id' => '654321',
                                           'source' => 'embedded_signup'
                                         })
      allow(channel).to receive(:validate_provider_config).and_return(true)
      allow(channel).to receive(:sync_templates).and_return(true)
      allow(channel).to receive(:setup_webhooks).and_return(true)
      channel.save!
      # Call authorization_error! twice to reach the threshold
      channel.authorization_error!
      channel.authorization_error!
      channel
    end
    let(:whatsapp_inbox) { create(:inbox, channel: whatsapp_channel, account: account) }

    context 'when user is an administrator' do
      let(:administrator) { create(:user, account: account, role: :administrator) }

      context 'with valid parameters' do
        let(:valid_params) do
          {
            code: 'auth_code_123',
            business_id: 'business_123',
            waba_id: 'waba_123',
            phone_number_id: 'phone_123'
          }
        end

        it 'reauthorizes the WhatsApp channel successfully' do
          allow(whatsapp_channel).to receive(:reauthorization_required?).and_return(true)

          embedded_signup_service = instance_double(Whatsapp::EmbeddedSignupService)
          allow(Whatsapp::EmbeddedSignupService).to receive(:new).with(
            account: account,
            params: {
              code: 'auth_code_123',
              business_id: 'business_123',
              waba_id: 'waba_123',
              phone_number_id: 'phone_123'
            },
            inbox_id: whatsapp_inbox.id
          ).and_return(embedded_signup_service)
          allow(embedded_signup_service).to receive(:perform).and_return(whatsapp_channel)
          allow(whatsapp_channel).to receive(:inbox).and_return(whatsapp_inbox)

          post "/api/v1/accounts/#{account.id}/whatsapp/authorization",
               params: valid_params.merge(inbox_id: whatsapp_inbox.id),
               headers: administrator.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:success)
          json_response = response.parsed_body
          expect(json_response['success']).to be true
          expect(json_response['id']).to eq(whatsapp_inbox.id)
        end

        it 'handles reauthorization failure' do
          embedded_signup_service = instance_double(Whatsapp::EmbeddedSignupService)
          allow(Whatsapp::EmbeddedSignupService).to receive(:new).with(
            account: account,
            params: {
              code: 'auth_code_123',
              business_id: 'business_123',
              waba_id: 'waba_123',
              phone_number_id: 'phone_123'
            },
            inbox_id: whatsapp_inbox.id
          ).and_return(embedded_signup_service)
          allow(embedded_signup_service).to receive(:perform)
            .and_raise(StandardError, 'Token exchange failed')

          post "/api/v1/accounts/#{account.id}/whatsapp/authorization",
               params: valid_params.merge(inbox_id: whatsapp_inbox.id),
               headers: administrator.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = response.parsed_body
          expect(json_response['success']).to be false
          expect(json_response['error']).to eq('Token exchange failed')
        end

        it 'handles phone number mismatch error' do
          embedded_signup_service = instance_double(Whatsapp::EmbeddedSignupService)
          allow(Whatsapp::EmbeddedSignupService).to receive(:new).with(
            account: account,
            params: {
              code: 'auth_code_123',
              business_id: 'business_123',
              waba_id: 'waba_123',
              phone_number_id: 'phone_123'
            },
            inbox_id: whatsapp_inbox.id
          ).and_return(embedded_signup_service)
          allow(embedded_signup_service).to receive(:perform)
            .and_raise(StandardError, 'Phone number mismatch. The new phone number (+1234567890) does not match ' \
                                      'the existing phone number (+15551234567). Please use the same WhatsApp ' \
                                      'Business Account that was originally connected.')

          post "/api/v1/accounts/#{account.id}/whatsapp/authorization",
               params: valid_params.merge(inbox_id: whatsapp_inbox.id),
               headers: administrator.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = response.parsed_body
          expect(json_response['success']).to be false
          expect(json_response['error']).to include('Phone number mismatch')
        end
      end

      context 'when inbox does not exist' do
        it 'returns not found error' do
          post "/api/v1/accounts/#{account.id}/whatsapp/authorization",
               params: { inbox_id: 0, code: 'test', business_id: 'test', waba_id: 'test' },
               headers: administrator.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:not_found)
        end
      end

      context 'when reauthorization is not required' do
        let(:fresh_channel) do
          channel = build(:channel_whatsapp, account: account, provider: 'whatsapp_cloud',
                                             provider_config: {
                                               'api_key' => 'test_token',
                                               'phone_number_id' => '123456',
                                               'business_account_id' => '654321',
                                               'source' => 'embedded_signup'
                                             })
          allow(channel).to receive(:validate_provider_config).and_return(true)
          allow(channel).to receive(:sync_templates).and_return(true)
          allow(channel).to receive(:setup_webhooks).and_return(true)
          channel.save!
          # Do NOT call authorization_error! - channel is working fine
          channel
        end
        let(:fresh_inbox) { create(:inbox, channel: fresh_channel, account: account) }

        it 'returns unprocessable entity error' do
          post "/api/v1/accounts/#{account.id}/whatsapp/authorization",
               params: { inbox_id: fresh_inbox.id },
               headers: administrator.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = response.parsed_body
          expect(json_response['success']).to be false
        end
      end

      context 'when channel is not WhatsApp' do
        let(:facebook_channel) do
          stub_request(:post, 'https://graph.facebook.com/v3.2/me/subscribed_apps')
            .to_return(status: 200, body: '{}', headers: {})

          channel = create(:channel_facebook_page, account: account)
          # Call authorization_error! twice to reach the threshold
          channel.authorization_error!
          channel.authorization_error!
          channel
        end
        let(:facebook_inbox) { create(:inbox, channel: facebook_channel, account: account) }

        it 'returns unprocessable entity error' do
          post "/api/v1/accounts/#{account.id}/whatsapp/authorization",
               params: { inbox_id: facebook_inbox.id },
               headers: administrator.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = response.parsed_body
          expect(json_response['success']).to be false
        end
      end
    end

    context 'when user is an agent' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, inbox: whatsapp_inbox, user: agent)
      end

      it 'returns unprocessable_entity error' do
        allow(whatsapp_channel).to receive(:reauthorization_required?).and_return(true)

        # Stub the embedded signup service to prevent HTTP calls
        embedded_signup_service = instance_double(Whatsapp::EmbeddedSignupService)
        allow(Whatsapp::EmbeddedSignupService).to receive(:new).with(
          account: account,
          params: {
            code: 'test',
            business_id: 'test',
            waba_id: 'test'
          },
          inbox_id: whatsapp_inbox.id
        ).and_return(embedded_signup_service)
        allow(embedded_signup_service).to receive(:perform).and_return(whatsapp_channel)

        post "/api/v1/accounts/#{account.id}/whatsapp/authorization",
             params: { inbox_id: whatsapp_inbox.id, code: 'test', business_id: 'test', waba_id: 'test' },
             headers: agent.create_new_auth_token,
             as: :json

        # Agents should get unprocessable_entity since they can find the inbox but channel doesn't need reauth
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when user is not authenticated' do
      it 'returns unauthorized error' do
        post "/api/v1/accounts/#{account.id}/whatsapp/authorization",
             params: { inbox_id: whatsapp_inbox.id },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'rate limiting' do
    let(:agent) { create(:user, account: account, role: :agent) }
    let(:waba_id) { 'test_waba_id' }
    let(:valid_params) do
      {
        code: 'test_code',
        business_id: 'test_business_id',
        waba_id: waba_id
      }
    end

    before do
      # Clear Redis keys before each test
      Redis::Alfred.del("whatsapp:connection_attempts:#{account.id}:#{waba_id}")
      Redis::Alfred.del("whatsapp:connection_failures:#{account.id}:#{waba_id}")
    end

    context 'when connection attempt tracker blocks the request' do
      before do
        # Simulate reaching the rate limit by recording max attempts
        tracker = Whatsapp::ConnectionAttemptTracker.new(account.id, waba_id)
        Whatsapp::ConnectionAttemptTracker::MAX_ATTEMPTS.times do
          tracker.record_attempt!(success: false)
        end
      end

      it 'returns 429 too many requests' do
        post "/api/v1/accounts/#{account.id}/whatsapp/authorization",
             params: valid_params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:too_many_requests)
      end

      it 'includes error details in the response' do
        post "/api/v1/accounts/#{account.id}/whatsapp/authorization",
             params: valid_params,
             headers: agent.create_new_auth_token,
             as: :json

        response_data = response.parsed_body
        expect(response_data['error']).to eq('rate_limit_exceeded')
        expect(response_data['status']).to be_a(Hash)
        expect(response_data['status']['can_attempt']).to be false
      end
    end

    context 'when in cooldown due to consecutive failures' do
      before do
        # Record 3 consecutive failures to trigger cooldown
        tracker = Whatsapp::ConnectionAttemptTracker.new(account.id, waba_id)
        3.times { tracker.record_attempt!(success: false) }
      end

      it 'returns 429 too many requests' do
        post "/api/v1/accounts/#{account.id}/whatsapp/authorization",
             params: valid_params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:too_many_requests)
      end

      it 'includes cooldown information in the response' do
        post "/api/v1/accounts/#{account.id}/whatsapp/authorization",
             params: valid_params,
             headers: agent.create_new_auth_token,
             as: :json

        response_data = response.parsed_body
        expect(response_data['status']['in_cooldown']).to be true
        expect(response_data['status']['cooldown_remaining']).to be > 0
      end
    end

    context 'when Facebook API returns rate limit error' do
      before do
        embedded_signup_service = instance_double(Whatsapp::EmbeddedSignupService)
        allow(Whatsapp::EmbeddedSignupService).to receive(:new).and_return(embedded_signup_service)
        allow(embedded_signup_service).to receive(:perform).and_raise(
          WhatsappRateLimitError.new('Rate limit exceeded', retry_after: 600, error_code: 80_008)
        )
      end

      it 'returns 429 too many requests' do
        post "/api/v1/accounts/#{account.id}/whatsapp/authorization",
             params: valid_params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:too_many_requests)
      end

      it 'includes retry_after in the response' do
        post "/api/v1/accounts/#{account.id}/whatsapp/authorization",
             params: valid_params,
             headers: agent.create_new_auth_token,
             as: :json

        response_data = response.parsed_body
        expect(response_data['error']).to eq('rate_limit_exceeded')
        expect(response_data['retry_after']).to eq(600)
        expect(response_data['error_code']).to eq(80_008)
      end

      it 'records a failed attempt' do
        tracker = Whatsapp::ConnectionAttemptTracker.new(account.id, waba_id)
        initial_attempts = tracker.current_attempts

        post "/api/v1/accounts/#{account.id}/whatsapp/authorization",
             params: valid_params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(tracker.current_attempts).to eq(initial_attempts + 1)
      end
    end

    context 'when request is successful' do
      let(:whatsapp_channel) { create(:channel_whatsapp, account: account, validate_provider_config: false, sync_templates: false) }
      let(:inbox) { create(:inbox, account: account, channel: whatsapp_channel) }

      before do
        embedded_signup_service = instance_double(Whatsapp::EmbeddedSignupService)
        allow(Whatsapp::EmbeddedSignupService).to receive(:new).and_return(embedded_signup_service)
        allow(embedded_signup_service).to receive(:perform).and_return(whatsapp_channel)
        allow(whatsapp_channel).to receive(:inbox).and_return(inbox)

        webhook_service = instance_double(Whatsapp::WebhookSetupService)
        allow(Whatsapp::WebhookSetupService).to receive(:new).and_return(webhook_service)
        allow(webhook_service).to receive(:perform)
      end

      it 'records a successful attempt' do
        tracker = Whatsapp::ConnectionAttemptTracker.new(account.id, waba_id)
        initial_attempts = tracker.current_attempts

        post "/api/v1/accounts/#{account.id}/whatsapp/authorization",
             params: valid_params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(tracker.current_attempts).to eq(initial_attempts + 1)
        expect(tracker.consecutive_failures).to eq(0)
      end

      it 'clears consecutive failures after a success' do
        # Record some failures first
        tracker = Whatsapp::ConnectionAttemptTracker.new(account.id, waba_id)
        2.times { tracker.record_attempt!(success: false) }
        expect(tracker.consecutive_failures).to eq(2)

        post "/api/v1/accounts/#{account.id}/whatsapp/authorization",
             params: valid_params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(tracker.consecutive_failures).to eq(0)
      end
    end

    context 'when request fails with a standard error' do
      before do
        allow(Whatsapp::EmbeddedSignupService).to receive(:new)
          .and_raise(StandardError, 'Service error')
      end

      it 'records a failed attempt' do
        tracker = Whatsapp::ConnectionAttemptTracker.new(account.id, waba_id)
        initial_attempts = tracker.current_attempts
        initial_failures = tracker.consecutive_failures

        post "/api/v1/accounts/#{account.id}/whatsapp/authorization",
             params: valid_params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(tracker.current_attempts).to eq(initial_attempts + 1)
        expect(tracker.consecutive_failures).to eq(initial_failures + 1)
      end
    end

    context 'when waba_id is not provided' do
      it 'skips rate limiting and processes the request' do
        post "/api/v1/accounts/#{account.id}/whatsapp/authorization",
             params: {
               code: 'test_code',
               business_id: 'test_business_id'
             },
             headers: agent.create_new_auth_token,
             as: :json

        # Should fail due to missing waba_id, not rate limiting
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to include('waba_id')
      end
    end
  end
end
