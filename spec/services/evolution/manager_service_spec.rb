require 'rails_helper'
require 'net/http'

RSpec.describe Evolution::ManagerService do
  subject(:service) { described_class.new }

  let(:account_id) { 123 }
  let(:instance_name) { 'test-instance' }
  let(:webhook_url) { 'https://evolution-api.example.com' }
  let(:api_key) { 'test-api-key' }
  let(:access_token) { 'test-access-token' }

  describe '#create' do
    let(:expected_url) { "#{webhook_url}/instance/create" }
    let(:success_response) { double('response', code: 201, success?: true, body: '{"success": true}') }

    before do
      stub_const('ENV', ENV.to_hash.merge(
                          'FRONTEND_URL' => 'http://localhost:3000',
                          'INTERNAL_API_URL' => nil
                        ))
      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:error)
    end

    context 'with valid parameters' do
      before do
        allow(HTTParty).to receive(:post).and_return(success_response)
      end

      it 'makes HTTP request with correct parameters' do
        service.create(account_id, instance_name, webhook_url, api_key, access_token)

        expect(HTTParty).to have_received(:post).with(
          expected_url,
          hash_including(
            headers: { 'apikey' => api_key, 'Content-Type' => 'application/json' },
            timeout: 30,
            open_timeout: 10,
            read_timeout: 20
          )
        )
      end

      it 'sends correct payload' do
        allow(HTTParty).to receive(:post) do |_url, options|
          payload = JSON.parse(options[:body])
          expect(payload['instanceName']).to eq(instance_name)
          expect(payload['chatwootAccountId']).to eq(account_id.to_s)
          expect(payload['chatwootToken']).to eq(access_token)
          expect(payload['integration']).to eq('WHATSAPP-BAILEYS')
          success_response
        end

        service.create(account_id, instance_name, webhook_url, api_key, access_token)
      end

      it 'returns parsed response body on success' do
        result = service.create(account_id, instance_name, webhook_url, api_key, access_token)
        expect(result).to eq({ 'success' => true })
      end

      it 'logs successful creation' do
        service.create(account_id, instance_name, webhook_url, api_key, access_token)
        expect(Rails.logger).to have_received(:info).with("Creating Evolution API instance: #{instance_name} for account: #{account_id}")
        expect(Rails.logger).to have_received(:info).with("Evolution API instance created successfully: #{instance_name}")
      end
    end

    context 'when input validation fails' do
      it 'raises InvalidConfiguration for missing webhook_url' do
        expect do
          service.create(account_id, instance_name, '', api_key, access_token)
        end.to raise_error(CustomExceptions::Evolution::InvalidConfiguration, /API URL is required/)
      end

      it 'raises InvalidConfiguration for missing api_key' do
        expect do
          service.create(account_id, instance_name, webhook_url, '', access_token)
        end.to raise_error(CustomExceptions::Evolution::InvalidConfiguration, /API key is required/)
      end

      it 'raises InvalidConfiguration for missing instance_name' do
        expect do
          service.create(account_id, '', webhook_url, api_key, access_token)
        end.to raise_error(CustomExceptions::Evolution::InvalidConfiguration, /Instance name is required/)
      end

      it 'raises InvalidConfiguration for invalid URL format' do
        expect do
          service.create(account_id, instance_name, 'not-a-url', api_key, access_token)
        end.to raise_error(CustomExceptions::Evolution::InvalidConfiguration, /Invalid API URL format/)
      end
    end

    context 'when HTTP request fails with network errors' do
      it 'raises NetworkTimeout for timeout errors' do
        allow(HTTParty).to receive(:post).and_raise(Timeout::Error)

        expect do
          service.create(account_id, instance_name, webhook_url, api_key, access_token)
        end.to raise_error(CustomExceptions::Evolution::NetworkTimeout)

        expect(Rails.logger).to have_received(:error).with(/Evolution API timeout for instance #{instance_name}/)
      end

      it 'raises NetworkTimeout for read timeout errors' do
        allow(HTTParty).to receive(:post).and_raise(Net::ReadTimeout)

        expect do
          service.create(account_id, instance_name, webhook_url, api_key, access_token)
        end.to raise_error(CustomExceptions::Evolution::NetworkTimeout)
      end

      it 'raises ConnectionRefused for connection refused errors' do
        allow(HTTParty).to receive(:post).and_raise(Errno::ECONNREFUSED)

        expect do
          service.create(account_id, instance_name, webhook_url, api_key, access_token)
        end.to raise_error(CustomExceptions::Evolution::ConnectionRefused)

        expect(Rails.logger).to have_received(:error).with(/Evolution API connection refused for instance #{instance_name}/)
      end

      it 'raises ServiceUnavailable for socket errors' do
        allow(HTTParty).to receive(:post).and_raise(SocketError)

        expect do
          service.create(account_id, instance_name, webhook_url, api_key, access_token)
        end.to raise_error(CustomExceptions::Evolution::ServiceUnavailable)

        expect(Rails.logger).to have_received(:error).with(%r{Evolution API DNS/network error for instance #{instance_name}})
      end

      it 'raises ServiceUnavailable for HTTParty errors' do
        allow(HTTParty).to receive(:post).and_raise(HTTParty::Error)

        expect do
          service.create(account_id, instance_name, webhook_url, api_key, access_token)
        end.to raise_error(CustomExceptions::Evolution::ServiceUnavailable)
      end
    end

    context 'when HTTP request returns error status codes' do
      it 'raises InvalidConfiguration for 400 Bad Request' do
        error_response = double('response', code: 400, body: '{"error": "Invalid payload"}')
        allow(HTTParty).to receive(:post).and_return(error_response)

        expect do
          service.create(account_id, instance_name, webhook_url, api_key, access_token)
        end.to raise_error(CustomExceptions::Evolution::InvalidConfiguration)

        expect(Rails.logger).to have_received(:error).with(/Evolution API bad request for instance #{instance_name}/)
      end

      it 'raises AuthenticationError for 401 Unauthorized' do
        error_response = double('response', code: 401, body: '{"error": "Unauthorized"}')
        allow(HTTParty).to receive(:post).and_return(error_response)

        expect do
          service.create(account_id, instance_name, webhook_url, api_key, access_token)
        end.to raise_error(CustomExceptions::Evolution::AuthenticationError)

        expect(Rails.logger).to have_received(:error).with(/Evolution API authentication failed for instance #{instance_name}/)
      end

      it 'raises AuthenticationError for 403 Forbidden' do
        error_response = double('response', code: 403, body: '{"error": "Forbidden"}')
        allow(HTTParty).to receive(:post).and_return(error_response)

        expect do
          service.create(account_id, instance_name, webhook_url, api_key, access_token)
        end.to raise_error(CustomExceptions::Evolution::AuthenticationError)
      end

      it 'raises InstanceConflict for 409 Conflict' do
        error_response = double('response', code: 409, body: '{"error": "Instance already exists"}')
        allow(HTTParty).to receive(:post).and_return(error_response)

        expect do
          service.create(account_id, instance_name, webhook_url, api_key, access_token)
        end.to raise_error(CustomExceptions::Evolution::InstanceConflict)

        expect(Rails.logger).to have_received(:error).with(/Evolution API instance conflict for instance #{instance_name}/)
      end

      it 'raises InstanceCreationFailed for 422 Unprocessable Entity' do
        error_response = double('response', code: 422, body: '{"message": "Creation failed"}')
        allow(HTTParty).to receive(:post).and_return(error_response)

        expect do
          service.create(account_id, instance_name, webhook_url, api_key, access_token)
        end.to raise_error(CustomExceptions::Evolution::InstanceCreationFailed)

        expect(Rails.logger).to have_received(:error).with(/Evolution API instance creation failed for instance #{instance_name}/)
      end

      it 'raises ServiceUnavailable for 503 Service Unavailable' do
        error_response = double('response', code: 503, body: '{"error": "Service unavailable"}')
        allow(HTTParty).to receive(:post).and_return(error_response)

        expect do
          service.create(account_id, instance_name, webhook_url, api_key, access_token)
        end.to raise_error(CustomExceptions::Evolution::ServiceUnavailable)

        expect(Rails.logger).to have_received(:error).with(/Evolution API service unavailable for instance #{instance_name}/)
      end

      it 'raises ServiceUnavailable for unknown status codes' do
        error_response = double('response', code: 500, body: '{"error": "Internal server error"}')
        allow(HTTParty).to receive(:post).and_return(error_response)

        expect do
          service.create(account_id, instance_name, webhook_url, api_key, access_token)
        end.to raise_error(CustomExceptions::Evolution::ServiceUnavailable)

        expect(Rails.logger).to have_received(:error).with(/Evolution API unexpected response for instance #{instance_name}: 500/)
      end
    end

    context 'error message extraction' do
      it 'extracts message from JSON response' do
        error_response = double('response', code: 400, body: '{"message": "Custom error message"}')
        allow(HTTParty).to receive(:post).and_return(error_response)

        expect do
          service.create(account_id, instance_name, webhook_url, api_key, access_token)
        end.to raise_error(CustomExceptions::Evolution::InvalidConfiguration) do |error|
          expect(error.instance_variable_get(:@data)[:details]).to eq('Custom error message')
        end
      end

      it 'extracts error from JSON response' do
        error_response = double('response', code: 400, body: '{"error": "Error message"}')
        allow(HTTParty).to receive(:post).and_return(error_response)

        expect do
          service.create(account_id, instance_name, webhook_url, api_key, access_token)
        end.to raise_error(CustomExceptions::Evolution::InvalidConfiguration) do |error|
          expect(error.instance_variable_get(:@data)[:details]).to eq('Error message')
        end
      end

      it 'falls back to raw body for invalid JSON' do
        error_response = double('response', code: 400, body: 'Plain text error')
        allow(HTTParty).to receive(:post).and_return(error_response)

        expect do
          service.create(account_id, instance_name, webhook_url, api_key, access_token)
        end.to raise_error(CustomExceptions::Evolution::InvalidConfiguration) do |error|
          expect(error.instance_variable_get(:@data)[:details]).to eq('Plain text error')
        end
      end

      it 'handles empty response body' do
        error_response = double('response', code: 400, body: '')
        allow(HTTParty).to receive(:post).and_return(error_response)

        expect do
          service.create(account_id, instance_name, webhook_url, api_key, access_token)
        end.to raise_error(CustomExceptions::Evolution::InvalidConfiguration) do |error|
          expect(error.instance_variable_get(:@data)[:details]).to eq('Unknown error')
        end
      end
    end

    context 'unexpected errors' do
      it 'raises InvalidConfiguration for unexpected StandardError' do
        allow(HTTParty).to receive(:post).and_raise(StandardError.new('Unexpected error'))

        expect do
          service.create(account_id, instance_name, webhook_url, api_key, access_token)
        end.to raise_error(CustomExceptions::Evolution::InvalidConfiguration)

        expect(Rails.logger).to have_received(:error).with(/Unexpected Evolution API error for instance #{instance_name}: Unexpected error/)
      end
    end
  end

  describe '#destroy' do
    let(:expected_url) { "#{webhook_url}/instance/delete/#{instance_name}" }
    let(:success_response) { double('response', code: 200, body: '{"success": true}') }

    before do
      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:warn)
    end

    context 'with valid parameters' do
      let(:logout_response) { double('logout_response', code: 200, body: '{}') }
      let(:instances_response) { double('instances_response', code: 200, parsed_response: []) }

      before do
        allow(HTTParty).to receive(:delete).with(
          "#{webhook_url}/instance/logout/#{instance_name}",
          anything
        ).and_return(logout_response)

        allow(HTTParty).to receive(:delete).with(
          expected_url,
          anything
        ).and_return(success_response)

        allow(HTTParty).to receive(:get).with(
          "#{webhook_url}/instance/fetchInstances",
          anything
        ).and_return(instances_response)
      end

      it 'makes HTTP DELETE request with correct parameters' do
        service.destroy(webhook_url, api_key, instance_name)

        expect(HTTParty).to have_received(:delete).with(
          "#{webhook_url}/instance/logout/#{instance_name}",
          hash_including(
            headers: { 'apikey' => api_key, 'Content-Type' => 'application/json' },
            timeout: 30,
            open_timeout: 10,
            read_timeout: 20
          )
        )

        expect(HTTParty).to have_received(:delete).with(
          expected_url,
          hash_including(
            headers: { 'apikey' => api_key, 'Content-Type' => 'application/json' },
            timeout: 30,
            open_timeout: 10,
            read_timeout: 20
          )
        )

        expect(HTTParty).to have_received(:get).with(
          "#{webhook_url}/instance/fetchInstances",
          hash_including(
            headers: { 'apikey' => api_key, 'Content-Type' => 'application/json' },
            timeout: 30,
            open_timeout: 10,
            read_timeout: 20
          )
        )
      end

      it 'logs successful destruction for 200 status' do
        service.destroy(webhook_url, api_key, instance_name)
        expect(Rails.logger).to have_received(:info).with("Starting Evolution API instance destruction: #{instance_name}")
        expect(Rails.logger).to have_received(:info).with("Logging out Evolution API instance: #{instance_name}")
        expect(Rails.logger).to have_received(:info).with("Deleting Evolution API instance: #{instance_name}")
        expect(Rails.logger).to have_received(:info).with("Evolution API instance logged out successfully: #{instance_name}")
        expect(Rails.logger).to have_received(:info).with("Evolution API instance destroyed successfully: #{instance_name}")
        expect(Rails.logger).to have_received(:info).with("Evolution instance successfully destroyed: #{instance_name}")
      end

      it 'logs successful destruction for 204 status' do
        no_content_response = double('response', code: 204, body: '')
        allow(HTTParty).to receive(:delete).with(
          "#{webhook_url}/instance/logout/#{instance_name}",
          anything
        ).and_return(logout_response)
        allow(HTTParty).to receive(:delete).with(
          expected_url,
          anything
        ).and_return(no_content_response)

        service.destroy(webhook_url, api_key, instance_name)
        expect(Rails.logger).to have_received(:info).with("Evolution API instance destroyed successfully: #{instance_name}")
      end

      it 'handles 404 not found gracefully' do
        not_found_response = double('response', code: 404, body: '{"error": "Instance not found"}')
        allow(HTTParty).to receive(:delete).with(
          "#{webhook_url}/instance/logout/#{instance_name}",
          anything
        ).and_return(logout_response)
        allow(HTTParty).to receive(:delete).with(
          expected_url,
          anything
        ).and_return(not_found_response)

        service.destroy(webhook_url, api_key, instance_name)
        expect(Rails.logger).to have_received(:info).with("Evolution API instance not found (already deleted): #{instance_name}")
      end
    end

    context 'when instance_name is blank' do
      it 'returns early without making HTTP request' do
        allow(HTTParty).to receive(:delete)

        service.destroy(webhook_url, api_key, '')
        expect(HTTParty).not_to have_received(:delete)
      end
    end

    context 'when input validation fails' do
      it 'raises InvalidConfiguration for missing webhook_url' do
        expect do
          service.destroy('', api_key, instance_name)
        end.to raise_error(CustomExceptions::Evolution::InvalidConfiguration, /API URL is required/)
      end

      it 'raises InvalidConfiguration for missing api_key' do
        expect do
          service.destroy(webhook_url, '', instance_name)
        end.to raise_error(CustomExceptions::Evolution::InvalidConfiguration, /API key is required/)
      end

      it 'raises InvalidConfiguration for invalid URL format' do
        expect do
          service.destroy('not-a-url', api_key, instance_name)
        end.to raise_error(CustomExceptions::Evolution::InvalidConfiguration, /Invalid API URL format/)
      end
    end

    context 'when HTTP request fails with network errors' do
      it 'handles timeout errors gracefully without raising' do
        allow(HTTParty).to receive(:delete).with(
          "#{webhook_url}/instance/logout/#{instance_name}",
          anything
        ).and_raise(Timeout::Error)
        allow(HTTParty).to receive(:delete).with(
          expected_url,
          anything
        ).and_raise(Timeout::Error)
        allow(HTTParty).to receive(:get).with(
          "#{webhook_url}/instance/fetchInstances",
          anything
        ).and_raise(Timeout::Error)

        expect do
          service.destroy(webhook_url, api_key, instance_name)
        end.not_to raise_error

        expect(Rails.logger).to have_received(:warn).with(/Evolution API timeout during instance #{instance_name} deletion/).at_least(1).times
      end

      it 'handles connection refused errors gracefully' do
        allow(HTTParty).to receive(:delete).with(
          "#{webhook_url}/instance/logout/#{instance_name}",
          anything
        ).and_raise(Errno::ECONNREFUSED)
        allow(HTTParty).to receive(:delete).with(
          expected_url,
          anything
        ).and_raise(Errno::ECONNREFUSED)
        allow(HTTParty).to receive(:get).with(
          "#{webhook_url}/instance/fetchInstances",
          anything
        ).and_raise(Errno::ECONNREFUSED)

        expect do
          service.destroy(webhook_url, api_key, instance_name)
        end.not_to raise_error

        expect(Rails.logger).to have_received(:warn).with(/Evolution API connection refused during instance #{instance_name} deletion/).at_least(1).times
      end

      it 'handles socket errors gracefully' do
        allow(HTTParty).to receive(:delete).with(
          "#{webhook_url}/instance/logout/#{instance_name}",
          anything
        ).and_raise(SocketError)
        allow(HTTParty).to receive(:delete).with(
          expected_url,
          anything
        ).and_raise(SocketError)
        allow(HTTParty).to receive(:get).with(
          "#{webhook_url}/instance/fetchInstances",
          anything
        ).and_raise(SocketError)

        expect do
          service.destroy(webhook_url, api_key, instance_name)
        end.not_to raise_error

        expect(Rails.logger).to have_received(:warn).with(%r{Evolution API DNS/network error during instance #{instance_name} deletion}).at_least(1).times
      end

      it 'handles HTTParty errors gracefully' do
        allow(HTTParty).to receive(:delete).with(
          "#{webhook_url}/instance/logout/#{instance_name}",
          anything
        ).and_raise(HTTParty::Error)
        allow(HTTParty).to receive(:delete).with(
          expected_url,
          anything
        ).and_raise(HTTParty::Error)
        allow(HTTParty).to receive(:get).with(
          "#{webhook_url}/instance/fetchInstances",
          anything
        ).and_raise(HTTParty::Error)

        expect do
          service.destroy(webhook_url, api_key, instance_name)
        end.not_to raise_error

        expect(Rails.logger).to have_received(:warn).with(/Evolution API HTTP error during instance #{instance_name} deletion/).at_least(1).times
      end

      it 'handles unexpected StandardError gracefully' do
        allow(HTTParty).to receive(:delete).with(
          "#{webhook_url}/instance/logout/#{instance_name}",
          anything
        ).and_raise(StandardError.new('Unexpected error'))
        allow(HTTParty).to receive(:delete).with(
          expected_url,
          anything
        ).and_raise(StandardError.new('Unexpected error'))
        allow(HTTParty).to receive(:get).with(
          "#{webhook_url}/instance/fetchInstances",
          anything
        ).and_raise(StandardError.new('Unexpected error'))

        expect do
          service.destroy(webhook_url, api_key, instance_name)
        end.not_to raise_error

        expect(Rails.logger).to have_received(:warn).with(/Unexpected Evolution API error during instance #{instance_name} deletion/).at_least(1).times
      end
    end

    context 'when HTTP request returns error status codes' do
      it 'handles authentication errors gracefully' do
        logout_response = double('logout_response', code: 401, body: '{"error": "Unauthorized"}')
        auth_error_response = double('response', code: 401, body: '{"error": "Unauthorized"}')
        instances_response = double('instances_response', code: 200, parsed_response: [])

        allow(HTTParty).to receive(:delete).with(
          "#{webhook_url}/instance/logout/#{instance_name}",
          anything
        ).and_return(logout_response)
        allow(HTTParty).to receive(:delete).with(
          expected_url,
          anything
        ).and_return(auth_error_response)
        allow(HTTParty).to receive(:get).with(
          "#{webhook_url}/instance/fetchInstances",
          anything
        ).and_return(instances_response)

        expect do
          service.destroy(webhook_url, api_key, instance_name)
        end.not_to raise_error

        expect(Rails.logger).to have_received(:warn).with(/Evolution API authentication failed during deletion for instance #{instance_name}/)
      end

      it 'handles forbidden errors gracefully' do
        logout_response = double('logout_response', code: 403, body: '{"error": "Forbidden"}')
        forbidden_response = double('response', code: 403, body: '{"error": "Forbidden"}')
        instances_response = double('instances_response', code: 200, parsed_response: [])

        allow(HTTParty).to receive(:delete).with(
          "#{webhook_url}/instance/logout/#{instance_name}",
          anything
        ).and_return(logout_response)
        allow(HTTParty).to receive(:delete).with(
          expected_url,
          anything
        ).and_return(forbidden_response)
        allow(HTTParty).to receive(:get).with(
          "#{webhook_url}/instance/fetchInstances",
          anything
        ).and_return(instances_response)

        expect do
          service.destroy(webhook_url, api_key, instance_name)
        end.not_to raise_error

        expect(Rails.logger).to have_received(:warn).with(/Evolution API authentication failed during deletion for instance #{instance_name}/)
      end

      it 'handles unexpected status codes gracefully' do
        logout_response = double('logout_response', code: 500, body: '{"error": "Internal server error"}')
        server_error_response = double('response', code: 500, body: '{"error": "Internal server error"}')
        instances_response = double('instances_response', code: 200, parsed_response: [])

        allow(HTTParty).to receive(:delete).with(
          "#{webhook_url}/instance/logout/#{instance_name}",
          anything
        ).and_return(logout_response)
        allow(HTTParty).to receive(:delete).with(
          expected_url,
          anything
        ).and_return(server_error_response)
        allow(HTTParty).to receive(:get).with(
          "#{webhook_url}/instance/fetchInstances",
          anything
        ).and_return(instances_response)

        expect do
          service.destroy(webhook_url, api_key, instance_name)
        end.not_to raise_error

        expect(Rails.logger).to have_received(:warn).with(/Evolution API unexpected response during deletion for instance #{instance_name}: 500/)
      end
    end
  end

  describe '#logout_instance' do
    let(:logout_url) { "#{webhook_url}/instance/logout/#{instance_name}" }
    let(:success_response) { double('response', code: 200, body: '{}') }

    before do
      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:warn)
    end

    context 'with valid parameters' do
      before do
        allow(HTTParty).to receive(:delete).and_return(success_response)
      end

      it 'makes HTTP DELETE request with correct parameters' do
        service.logout_instance(webhook_url, api_key, instance_name)

        expect(HTTParty).to have_received(:delete).with(
          logout_url,
          hash_including(
            headers: { 'apikey' => api_key, 'Content-Type' => 'application/json' },
            timeout: 30,
            open_timeout: 10,
            read_timeout: 20
          )
        )
      end

      it 'logs successful logout for 200 status' do
        service.logout_instance(webhook_url, api_key, instance_name)
        expect(Rails.logger).to have_received(:info).with("Logging out Evolution API instance: #{instance_name}")
        expect(Rails.logger).to have_received(:info).with("Evolution API instance logged out successfully: #{instance_name}")
      end

      it 'handles 404 not found gracefully' do
        not_found_response = double('response', code: 404, body: '{"error": "Instance not found"}')
        allow(HTTParty).to receive(:delete).and_return(not_found_response)

        service.logout_instance(webhook_url, api_key, instance_name)
        expect(Rails.logger).to have_received(:info).with("Evolution API instance not found during logout (may already be logged out): #{instance_name}")
      end
    end
  end

  describe '#instance_status' do
    let(:status_url) { "#{webhook_url}/instance/fetchInstances" }

    before do
      allow(Rails.logger).to receive(:warn)
    end

    context 'when instance exists' do
      let(:instances_response) do
        double('response',
               code: 200,
               parsed_response: [
                 { 'instance' => { 'instanceName' => 'other-instance' } },
                 { 'instance' => { 'instanceName' => instance_name } }
               ])
      end

      before do
        allow(HTTParty).to receive(:get).and_return(instances_response)
      end

      it 'returns instance data when found' do
        result = service.instance_status(webhook_url, api_key, instance_name)
        expect(result).to eq({ 'instance' => { 'instanceName' => instance_name } })
      end
    end

    context 'when instance does not exist' do
      let(:instances_response) do
        double('response',
               code: 200,
               parsed_response: [
                 { 'instance' => { 'instanceName' => 'other-instance' } }
               ])
      end

      before do
        allow(HTTParty).to receive(:get).and_return(instances_response)
      end

      it 'returns nil when not found' do
        result = service.instance_status(webhook_url, api_key, instance_name)
        expect(result).to be_nil
      end
    end

    context 'when API call fails' do
      before do
        allow(HTTParty).to receive(:get).and_raise(StandardError.new('API error'))
      end

      it 'returns nil on error' do
        result = service.instance_status(webhook_url, api_key, instance_name)
        expect(result).to be_nil
      end
    end
  end

  describe '#verify_instance_destroyed' do
    before do
      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:error)
      allow(Rails.logger).to receive(:warn)
    end

    context 'when instance is destroyed' do
      before do
        allow(service).to receive(:instance_status).and_return(nil)
      end

      it 'returns true and logs success' do
        result = service.verify_instance_destroyed(webhook_url, api_key, instance_name)
        expect(result).to be true
        expect(Rails.logger).to have_received(:info).with("Evolution instance successfully destroyed: #{instance_name}")
      end
    end

    context 'when instance still exists' do
      before do
        allow(service).to receive(:instance_status).and_return({ 'instance' => { 'instanceName' => instance_name } })
      end

      it 'returns false and logs error' do
        result = service.verify_instance_destroyed(webhook_url, api_key, instance_name)
        expect(result).to be false
        expect(Rails.logger).to have_received(:error).with("Evolution instance still exists after deletion: #{instance_name}")
      end
    end

    context 'when verification fails' do
      before do
        allow(service).to receive(:instance_status).and_raise(StandardError.new('Verification error'))
      end

      it 'returns true and logs warning' do
        result = service.verify_instance_destroyed(webhook_url, api_key, instance_name)
        expect(result).to be true
        expect(Rails.logger).to have_received(:warn).with("Could not verify Evolution instance destruction for #{instance_name}: Verification error")
      end
    end
  end

  describe '#api_headers' do
    it 'returns correct headers' do
      headers = service.api_headers('test-key')
      expect(headers).to eq({
                              'apikey' => 'test-key',
                              'Content-Type' => 'application/json'
                            })
    end
  end
end
