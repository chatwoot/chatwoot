require 'rails_helper'

RSpec.describe 'WhatsApp Phone Registrations API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:inbox) { create(:inbox, account: account, channel: whatsapp_channel) }
  let(:whatsapp_channel) do
    create(:channel_whatsapp,
           phone_number: '+1234567890',
           provider: 'whatsapp_cloud',
           sync_templates: false,
           validate_provider_config: false,
           provider_config: {
             'phone_number_id' => 'test_phone_id',
             'business_account_id' => 'test_business_id',
             'api_key' => 'test_api_key',
             'webhook_verify_token' => 'test_verify_token'
           })
  end

  describe 'POST /api/v1/accounts/{account.id}/whatsapp/phone_registrations' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/whatsapp/phone_registrations",
             params: {
               inbox_id: inbox.id,
               waba_id: 'test_waba_id',
               access_token: 'test_access_token'
             },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/whatsapp/phone_registrations",
             params: {
               inbox_id: inbox.id,
               waba_id: 'test_waba_id',
               access_token: 'test_access_token'
             },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      context 'with valid params' do
        let(:service_double) { instance_double(Whatsapp::WebhookSetupService) }

        before do
          allow(Whatsapp::WebhookSetupService).to receive(:new)
            .with(whatsapp_channel, 'test_waba_id', 'test_access_token')
            .and_return(service_double)
          allow(service_double).to receive(:perform).and_return(true)
        end

        it 'returns success response' do
          post "/api/v1/accounts/#{account.id}/whatsapp/phone_registrations",
               params: {
                 inbox_id: inbox.id,
                 waba_id: 'test_waba_id',
                 access_token: 'test_access_token'
               },
               headers: administrator.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:success)
          expect(response.parsed_body['success']).to be true
          expect(response.parsed_body['message']).to eq('Phone number registered and webhook setup completed successfully')
          expect(response.parsed_body['inbox_id']).to eq(inbox.id)
        end

        it 'calls WebhookSetupService with correct params' do
          service_double = instance_double(Whatsapp::WebhookSetupService)
          expect(Whatsapp::WebhookSetupService).to receive(:new)
            .with(whatsapp_channel, 'test_waba_id', 'test_access_token')
            .and_return(service_double)
          expect(service_double).to receive(:perform)

          post "/api/v1/accounts/#{account.id}/whatsapp/phone_registrations",
               params: {
                 inbox_id: inbox.id,
                 waba_id: 'test_waba_id',
                 access_token: 'test_access_token'
               },
               headers: administrator.create_new_auth_token,
               as: :json
        end
      end

      context 'with missing params' do
        it 'returns error when inbox_id is missing' do
          post "/api/v1/accounts/#{account.id}/whatsapp/phone_registrations",
               params: {
                 waba_id: 'test_waba_id',
                 access_token: 'test_access_token'
               },
               headers: administrator.create_new_auth_token,
               as: :json

          # When inbox_id is not provided, find(nil) raises RecordNotFound
          # which is handled by the framework's exception handler and returns 404
          expect(response).to have_http_status(:not_found)
          expect(response.parsed_body['error']).to eq('Resource could not be found')
        end

        it 'returns error when waba_id is missing' do
          post "/api/v1/accounts/#{account.id}/whatsapp/phone_registrations",
               params: {
                 inbox_id: inbox.id,
                 access_token: 'test_access_token'
               },
               headers: administrator.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body['success']).to be false
          expect(response.parsed_body['error']).to eq('WABA ID is required')
        end

        it 'returns error when access_token is missing' do
          post "/api/v1/accounts/#{account.id}/whatsapp/phone_registrations",
               params: {
                 inbox_id: inbox.id,
                 waba_id: 'test_waba_id'
               },
               headers: administrator.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body['success']).to be false
          expect(response.parsed_body['error']).to eq('Access token is required')
        end
      end

      context 'with non-WhatsApp inbox' do
        let(:non_whatsapp_inbox) { create(:inbox, account: account, channel: create(:channel_api)) }

        it 'returns error' do
          post "/api/v1/accounts/#{account.id}/whatsapp/phone_registrations",
               params: {
                 inbox_id: non_whatsapp_inbox.id,
                 waba_id: 'test_waba_id',
                 access_token: 'test_access_token'
               },
               headers: administrator.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body['success']).to be false
          expect(response.parsed_body['message']).to eq('Inbox must be a WhatsApp channel')
        end
      end

      context 'when WebhookSetupService raises error' do
        it 'returns error response' do
          service_double = instance_double(Whatsapp::WebhookSetupService)
          allow(Whatsapp::WebhookSetupService).to receive(:new)
            .with(whatsapp_channel, 'test_waba_id', 'test_access_token')
            .and_return(service_double)
          allow(service_double).to receive(:perform)
            .and_raise(StandardError, 'Webhook setup failed')

          post "/api/v1/accounts/#{account.id}/whatsapp/phone_registrations",
               params: {
                 inbox_id: inbox.id,
                 waba_id: 'test_waba_id',
                 access_token: 'test_access_token'
               },
               headers: administrator.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body['success']).to be false
          expect(response.parsed_body['error']).to eq('Webhook setup failed')
        end
      end
    end
  end
end
