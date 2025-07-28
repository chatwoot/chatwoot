require 'rails_helper'

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

      context 'when feature is not enabled' do
        before do
          account.disable_features!(:whatsapp_embedded_signup)
        end

        it 'returns forbidden' do
          post "/api/v1/accounts/#{account.id}/whatsapp/authorization",
               params: {
                 code: 'test_code',
                 business_id: 'test_business_id',
                 waba_id: 'test_waba_id'
               },
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:forbidden)
          expect(response.parsed_body['error']).to eq('WhatsApp embedded signup is not enabled for this account')
        end
      end

      context 'when feature is enabled' do
        before do
          account.enable_features!(:whatsapp_embedded_signup)
        end

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
            code: 'test_code',
            business_id: 'test_business_id',
            waba_id: 'test_waba_id',
            phone_number_id: 'test_phone_id'
          ).and_return(embedded_signup_service)

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
            code: 'test_code',
            business_id: 'test_business_id',
            waba_id: 'test_waba_id',
            phone_number_id: nil
          ).and_return(embedded_signup_service)

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

        before do
          account.enable_features!(:whatsapp_embedded_signup)
        end

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
        before do
          account.enable_features!(:whatsapp_embedded_signup)
        end

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
end
