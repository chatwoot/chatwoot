require 'rails_helper'

RSpec.describe 'WhatsApp Reauthorizations API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:whatsapp_channel) do
    channel = build(:channel_whatsapp, account: account, provider: 'whatsapp_cloud',
                                       provider_config: {
                                         'api_key' => 'test_token',
                                         'phone_number_id' => '123456',
                                         'business_account_id' => '654321',
                                         'source' => 'embedded_signup'
                                       })
    allow(channel).to receive(:validate_provider_config).and_return(true)
    channel.save!
    channel.authorization_error!  # Mark as requiring reauthorization
    channel
  end
  let(:whatsapp_inbox) { create(:inbox, channel: whatsapp_channel, account: account) }

  before do
    allow(whatsapp_channel).to receive(:validate_provider_config).and_return(true)
    allow(whatsapp_channel).to receive(:sync_templates).and_return(true)
    allow(whatsapp_channel).to receive(:setup_webhooks).and_return(true)
  end

  describe 'POST /api/v1/accounts/{account.id}/whatsapp/reauthorizations' do
    context 'when user is an administrator' do
      context 'with valid parameters' do
        let(:valid_params) do
          {
            inbox_id: whatsapp_inbox.id,
            code: 'auth_code_123',
            business_id: 'business_123',
            waba_id: 'waba_123',
            phone_number_id: 'phone_123'
          }
        end

        before do
          # Ensure channel is marked as requiring reauthorization
          allow(whatsapp_channel).to receive(:reauthorization_required?).and_return(true)
        end

        it 'reauthorizes the WhatsApp channel successfully' do
          reauth_service = instance_double(Whatsapp::ReauthorizationService)
          allow(Whatsapp::ReauthorizationService).to receive(:new).with(
            code: 'auth_code_123',
            business_id: 'business_123',
            waba_id: 'waba_123',
            phone_number_id: 'phone_123',
            inbox: whatsapp_inbox
          ).and_return(reauth_service)
          allow(reauth_service).to receive(:perform).and_return({ success: true })

          post "/api/v1/accounts/#{account.id}/whatsapp/reauthorizations",
               params: valid_params,
               headers: admin.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:success)
          json_response = response.parsed_body
          expect(json_response['success']).to be true
          expect(json_response['inbox_id']).to eq(whatsapp_inbox.id)
        end

        it 'handles reauthorization failure' do
          reauth_service = instance_double(Whatsapp::ReauthorizationService)
          allow(Whatsapp::ReauthorizationService).to receive(:new).with(
            code: 'auth_code_123',
            business_id: 'business_123',
            waba_id: 'waba_123',
            phone_number_id: 'phone_123',
            inbox: whatsapp_inbox
          ).and_return(reauth_service)
          allow(reauth_service).to receive(:perform).and_return({ success: false, message: 'Token exchange failed' })

          post "/api/v1/accounts/#{account.id}/whatsapp/reauthorizations",
               params: valid_params,
               headers: admin.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = response.parsed_body
          expect(json_response['success']).to be false
          expect(json_response['message']).to eq('Token exchange failed')
        end
      end

      context 'when inbox does not exist' do
        it 'returns not found error' do
          post "/api/v1/accounts/#{account.id}/whatsapp/reauthorizations",
               params: { inbox_id: 0 },
               headers: admin.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:not_found)
        end
      end

      context 'when reauthorization is not required' do
        it 'returns unprocessable entity error' do
          # Mark channel as NOT requiring reauthorization
          allow(whatsapp_channel).to receive(:reauthorization_required?).and_return(false)

          post "/api/v1/accounts/#{account.id}/whatsapp/reauthorizations",
               params: { inbox_id: whatsapp_inbox.id },
               headers: admin.create_new_auth_token,
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

          channel = build(:channel_facebook_page, account: account)
          allow(channel).to receive(:reauthorization_required?).and_return(true)
          channel.save!
          channel.authorization_error!
          channel
        end
        let(:facebook_inbox) { create(:inbox, channel: facebook_channel, account: account) }

        it 'returns unprocessable entity error' do
          post "/api/v1/accounts/#{account.id}/whatsapp/reauthorizations",
               params: { inbox_id: facebook_inbox.id },
               headers: admin.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = response.parsed_body
          expect(json_response['success']).to be false
        end
      end
    end

    context 'when user is an agent' do
      it 'returns unauthorized error' do
        post "/api/v1/accounts/#{account.id}/whatsapp/reauthorizations",
             params: { inbox_id: whatsapp_inbox.id },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is not authenticated' do
      it 'returns unauthorized error' do
        post "/api/v1/accounts/#{account.id}/whatsapp/reauthorizations",
             params: { inbox_id: whatsapp_inbox.id },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
