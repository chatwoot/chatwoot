require 'rails_helper'

RSpec.describe Api::V1::Accounts::Channels::EvolutionChannelsController, type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:evolution_manager_service) { instance_double(Evolution::ManagerService) }
  let(:evolution_api_url) { 'https://evolution-api.example.com' }
  let(:evolution_api_key) { 'test-api-key' }

  before do
    allow(Evolution::ManagerService).to receive(:new).and_return(evolution_manager_service)
    stub_const('ENV', ENV.to_hash.merge(
                        'EVOLUTION_API_URL' => evolution_api_url,
                        'EVOLUTION_API_KEY' => evolution_api_key
                      ))
  end

  describe 'POST /api/v1/accounts/{account.id}/channels/evolution_channel' do
    let(:base_params) do
      {
        name: 'Evolution Channel',
        channel: {
          type: 'whatsapp',
          webhook_url: evolution_api_url,
          api_key: evolution_api_key
        }
      }
    end

    context 'when unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/channels/evolution_channel", params: base_params
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is logged in as agent' do
      it 'returns forbidden' do
        post "/api/v1/accounts/#{account.id}/channels/evolution_channel",
             params: base_params,
             headers: agent.create_new_auth_token

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when user is logged in as administrator' do
      let(:headers) { admin.create_new_auth_token }

      context 'with valid parameters' do
        before do
          allow(evolution_manager_service).to receive(:create).and_return({ 'success' => true })
        end

        it 'creates inbox and returns success' do
          post "/api/v1/accounts/#{account.id}/channels/evolution_channel",
               params: base_params,
               headers: headers

          expect(response).to have_http_status(:created)
          json_response = response.parsed_body
          expect(json_response['name']).to eq('Evolution Channel')
        end
      end

      context 'when Evolution API URL is missing' do
        before do
          stub_const('ENV', ENV.to_hash.merge(
                              'EVOLUTION_API_URL' => nil,
                              'EVOLUTION_API_KEY' => evolution_api_key
                            ))
        end

        let(:params_without_url) do
          base_params.tap { |p| p[:channel].delete(:webhook_url) }
        end

        it 'returns bad request with specific error code' do
          post "/api/v1/accounts/#{account.id}/channels/evolution_channel",
               params: params_without_url,
               headers: headers

          expect(response).to have_http_status(:bad_request)
          json_response = response.parsed_body
          expect(json_response['error']).to include('Evolution API URL is missing')
          expect(json_response['error_code']).to eq('EVOLUTION_INVALID_CONFIG')
        end
      end

      context 'when Evolution API service is unavailable' do
        before do
          allow(evolution_manager_service).to receive(:create)
            .and_raise(CustomExceptions::Evolution::ServiceUnavailable.new({}))
        end

        it 'returns service unavailable with specific error code' do
          post "/api/v1/accounts/#{account.id}/channels/evolution_channel",
               params: base_params,
               headers: headers

          expect(response).to have_http_status(:service_unavailable)
          json_response = response.parsed_body
          expect(json_response['error_code']).to eq('EVOLUTION_SERVICE_UNAVAILABLE')
          expect(json_response['error']).to include('Evolution API service is currently unavailable')
        end
      end

      context 'when Evolution API authentication fails' do
        before do
          allow(evolution_manager_service).to receive(:create)
            .and_raise(CustomExceptions::Evolution::AuthenticationError.new({}))
        end

        it 'returns unauthorized with specific error code' do
          post "/api/v1/accounts/#{account.id}/channels/evolution_channel",
               params: base_params,
               headers: headers

          expect(response).to have_http_status(:unauthorized)
          json_response = response.parsed_body
          expect(json_response['error_code']).to eq('EVOLUTION_AUTH_FAILED')
          expect(json_response['error']).to include('Authentication with Evolution API failed')
        end
      end

      context 'when Evolution API times out' do
        before do
          allow(evolution_manager_service).to receive(:create)
            .and_raise(CustomExceptions::Evolution::NetworkTimeout.new({}))
        end

        it 'returns gateway timeout with specific error code' do
          post "/api/v1/accounts/#{account.id}/channels/evolution_channel",
               params: base_params,
               headers: headers

          expect(response).to have_http_status(:gateway_timeout)
          json_response = response.parsed_body
          expect(json_response['error_code']).to eq('EVOLUTION_NETWORK_TIMEOUT')
          expect(json_response['error']).to include('Connection to Evolution API timed out')
        end
      end

      context 'when instance name already exists' do
        before do
          allow(evolution_manager_service).to receive(:create)
            .and_raise(CustomExceptions::Evolution::InstanceConflict.new(instance_name: 'Evolution Channel'))
        end

        it 'returns conflict with specific error code' do
          post "/api/v1/accounts/#{account.id}/channels/evolution_channel",
               params: base_params,
               headers: headers

          expect(response).to have_http_status(:conflict)
          json_response = response.parsed_body
          expect(json_response['error_code']).to eq('EVOLUTION_INSTANCE_EXISTS')
          expect(json_response['error']).to include('Evolution Channel')
        end
      end

      context 'when instance creation fails' do
        before do
          allow(evolution_manager_service).to receive(:create)
            .and_raise(CustomExceptions::Evolution::InstanceCreationFailed.new(reason: 'Invalid payload'))
        end

        it 'returns unprocessable entity with specific error code' do
          post "/api/v1/accounts/#{account.id}/channels/evolution_channel",
               params: base_params,
               headers: headers

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = response.parsed_body
          expect(json_response['error_code']).to eq('EVOLUTION_INSTANCE_CREATION_FAILED')
          expect(json_response['error']).to include('Invalid payload')
        end
      end

      context 'when connection is refused' do
        before do
          allow(evolution_manager_service).to receive(:create)
            .and_raise(CustomExceptions::Evolution::ConnectionRefused.new({}))
        end

        it 'returns service unavailable with specific error code' do
          post "/api/v1/accounts/#{account.id}/channels/evolution_channel",
               params: base_params,
               headers: headers

          expect(response).to have_http_status(:service_unavailable)
          json_response = response.parsed_body
          expect(json_response['error_code']).to eq('EVOLUTION_CONNECTION_REFUSED')
          expect(json_response['error']).to include('Unable to connect to Evolution API')
        end
      end

      context 'when invalid configuration is provided' do
        before do
          allow(evolution_manager_service).to receive(:create)
            .and_raise(CustomExceptions::Evolution::InvalidConfiguration.new(details: 'Missing required field'))
        end

        it 'returns bad request with specific error code' do
          post "/api/v1/accounts/#{account.id}/channels/evolution_channel",
               params: base_params,
               headers: headers

          expect(response).to have_http_status(:bad_request)
          json_response = response.parsed_body
          expect(json_response['error_code']).to eq('EVOLUTION_INVALID_CONFIG')
          expect(json_response['error']).to include('Missing required field')
        end
      end

      context 'when database validation fails' do
        before do
          allow(evolution_manager_service).to receive(:create).and_return({ 'success' => true })
          # Simulate database validation failure
          allow_any_instance_of(Inbox).to receive(:save!).and_raise(
            ActiveRecord::RecordInvalid.new(Inbox.new.tap { |i| i.errors.add(:name, 'is required') })
          )
        end

        it 'returns bad request with database error details' do
          post "/api/v1/accounts/#{account.id}/channels/evolution_channel",
               params: base_params,
               headers: headers

          expect(response).to have_http_status(:bad_request)
          json_response = response.parsed_body
          expect(json_response['error_code']).to eq('EVOLUTION_INVALID_CONFIG')
          expect(json_response['error']).to include('Database validation failed')
        end
      end

      context 'when unexpected error occurs' do
        before do
          allow(evolution_manager_service).to receive(:create)
            .and_raise(StandardError.new('Unexpected system error'))
        end

        it 'returns bad request with generic error handling' do
          post "/api/v1/accounts/#{account.id}/channels/evolution_channel",
               params: base_params,
               headers: headers

          expect(response).to have_http_status(:bad_request)
          json_response = response.parsed_body
          expect(json_response['error_code']).to eq('EVOLUTION_INVALID_CONFIG')
          expect(json_response['error']).to include('Unexpected error')
        end
      end

      context 'in development environment' do
        before do
          allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development'))
          allow(evolution_manager_service).to receive(:create)
            .and_raise(CustomExceptions::Evolution::ServiceUnavailable.new(test_data: 'debug_info'))
        end

        it 'includes debug information in response' do
          post "/api/v1/accounts/#{account.id}/channels/evolution_channel",
               params: base_params,
               headers: headers

          expect(response).to have_http_status(:service_unavailable)
          json_response = response.parsed_body
          expect(json_response).to have_key('details')
          expect(json_response['details']).to have_key('exception_class')
          expect(json_response['details']).to have_key('data')
        end
      end
    end
  end
end
