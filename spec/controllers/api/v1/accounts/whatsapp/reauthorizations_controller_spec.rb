require 'rails_helper'

RSpec.describe Api::V1::Accounts::Whatsapp::ReauthorizationsController, type: :controller do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:whatsapp_channel) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud',
                              provider_config: {
                                'api_key' => 'test_token',
                                'phone_number_id' => '123456',
                                'business_account_id' => '654321',
                                'source' => 'embedded_signup'
                              })
  end
  let(:whatsapp_inbox) { create(:inbox, channel: whatsapp_channel, account: account) }

  before do
    allow(whatsapp_channel).to receive(:reauthorization_required?).and_return(true)
  end

  describe 'POST #create' do
    context 'when user is an administrator' do
      before { sign_in(admin) }

      context 'with valid parameters' do
        let(:valid_params) do
          {
            account_id: account.id,
            inbox_id: whatsapp_inbox.id,
            code: 'auth_code_123',
            business_id: 'business_123',
            waba_id: 'waba_123',
            phone_number_id: 'phone_123'
          }
        end

        it 'reauthorizes the WhatsApp channel successfully' do
          reauth_service = instance_double(Whatsapp::ReauthorizationService)
          allow(Whatsapp::ReauthorizationService).to receive(:new).and_return(reauth_service)
          allow(reauth_service).to receive(:perform).and_return({ success: true })

          post :create, params: valid_params

          expect(response).to have_http_status(:success)
          json_response = response.parsed_body
          expect(json_response['success']).to be true
          expect(json_response['inbox_id']).to eq(whatsapp_inbox.id)
        end

        it 'handles reauthorization failure' do
          reauth_service = instance_double(Whatsapp::ReauthorizationService)
          allow(Whatsapp::ReauthorizationService).to receive(:new).and_return(reauth_service)
          allow(reauth_service).to receive(:perform).and_return({ success: false, message: 'Token exchange failed' })

          post :create, params: valid_params

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = response.parsed_body
          expect(json_response['success']).to be false
          expect(json_response['message']).to eq('Token exchange failed')
        end
      end

      context 'when inbox does not exist' do
        it 'returns not found error' do
          post :create, params: { account_id: account.id, inbox_id: 0 }

          expect(response).to have_http_status(:not_found)
        end
      end

      context 'when reauthorization is not required' do
        it 'returns unprocessable entity error' do
          allow(whatsapp_channel).to receive(:reauthorization_required?).and_return(false)

          post :create, params: { account_id: account.id, inbox_id: whatsapp_inbox.id }

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = response.parsed_body
          expect(json_response['success']).to be false
        end
      end

      context 'when channel is not WhatsApp' do
        let(:facebook_channel) { create(:channel_facebook_page, account: account) }
        let(:facebook_inbox) { create(:inbox, channel: facebook_channel, account: account) }

        it 'returns unprocessable entity error' do
          post :create, params: { account_id: account.id, inbox_id: facebook_inbox.id }

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = response.parsed_body
          expect(json_response['success']).to be false
        end
      end
    end

    context 'when user is an agent' do
      before { sign_in(agent) }

      it 'returns unauthorized error' do
        post :create, params: { account_id: account.id, inbox_id: whatsapp_inbox.id }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is not authenticated' do
      it 'returns unauthorized error' do
        post :create, params: { account_id: account.id, inbox_id: whatsapp_inbox.id }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
