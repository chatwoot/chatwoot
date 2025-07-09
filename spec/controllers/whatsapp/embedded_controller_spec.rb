require 'rails_helper'

RSpec.describe 'WhatsApp Embedded API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }

  describe 'GET /whatsapp/signup' do
    before do
      allow(GlobalConfigService).to receive(:load).with('WHATSAPP_APP_ID', '').and_return('test_app_id')
      allow(GlobalConfigService).to receive(:load).with('WHATSAPP_CONFIGURATION_ID', '').and_return('test_config_id')
      allow(GlobalConfigService).to receive(:load).with('WHATSAPP_APP_SECRET', '').and_return('test_app_secret')
      allow(GlobalConfigService).to receive(:load).with('WHATSAPP_API_VERSION', '').and_return('v22.0')
    end

    context 'when user is authenticated' do
      it 'returns configuration for embedded signup' do
        get '/whatsapp/signup',
            headers: admin.create_new_auth_token,
            params: { account_id: account.id }

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response).to include(
          'status' => 'ready',
          'app_id' => 'test_app_id',
          'config_id' => 'test_config_id',
          'app_secret' => 'test_app_secret'
        )
      end
    end

    context 'when user is not authenticated' do
      it 'returns unauthorized' do
        get '/whatsapp/signup', params: { account_id: account.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /whatsapp/embedded_signup' do
    let(:params) do
      {
        account_id: account.id,
        code: 'auth_code_123',
        business_id: '123456789',
        waba_id: '987654321',
        phone_number_id: '555444333'
      }
    end

    context 'when user is authenticated' do
      context 'with missing authorization code' do
        it 'returns bad request error' do
          params_without_code = params.except(:code)

          post '/whatsapp/embedded_signup',
               headers: admin.create_new_auth_token,
               params: params_without_code

          expect(response).to have_http_status(:bad_request)
          json_response = response.parsed_body
          expect(json_response['error']).to eq('Missing authorization code')
        end
      end

      context 'with missing business parameters' do
        it 'returns bad request when business_id is missing' do
          params_without_business = params.except(:business_id)

          post '/whatsapp/embedded_signup',
               headers: admin.create_new_auth_token,
               params: params_without_business

          expect(response).to have_http_status(:bad_request)
          json_response = response.parsed_body
          expect(json_response['error']).to include('Missing required parameters')
        end

        it 'returns bad request when waba_id is missing' do
          params_without_waba = params.except(:waba_id)

          post '/whatsapp/embedded_signup',
               headers: admin.create_new_auth_token,
               params: params_without_waba

          expect(response).to have_http_status(:bad_request)
          json_response = response.parsed_body
          expect(json_response['error']).to include('Missing required parameters')
        end
      end
    end

    context 'when user is not authenticated' do
      it 'returns unauthorized' do
        post '/whatsapp/embedded_signup', params: params
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
