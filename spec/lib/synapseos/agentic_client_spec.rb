require 'rails_helper'
require 'synapseos/agentic_client'

RSpec.describe Synapseos::AgenticClient do
  let(:base_url) { 'http://agentic.test' }
  let(:user) { 'admin' }
  let(:password) { 's3cret' }
  let(:client) { described_class.new(base_url: base_url, user: user, password: password) }
  let(:basic_auth_header) { "Basic #{Base64.strict_encode64("#{user}:#{password}")}" }

  describe '#initialize' do
    it 'raises ArgumentError when base_url is blank' do
      expect { described_class.new(base_url: '', user: user, password: password) }.to raise_error(ArgumentError)
    end

    it 'raises ArgumentError when user is blank' do
      expect { described_class.new(base_url: base_url, user: '', password: password) }.to raise_error(ArgumentError)
    end

    it 'raises ArgumentError when password is blank' do
      expect { described_class.new(base_url: base_url, user: user, password: '') }.to raise_error(ArgumentError)
    end
  end

  describe '#health' do
    it 'returns success with parsed body and sends basic auth' do
      stub = stub_request(:get, "#{base_url}/api/health")
             .with(headers: { 'Authorization' => basic_auth_header })
             .to_return(status: 200, body: { status: 'ok' }.to_json, headers: { 'Content-Type' => 'application/json' })

      result = client.health
      expect(result.ok?).to be true
      expect(result.data).to eq('status' => 'ok')
      expect(stub).to have_been_requested
    end
  end

  describe '#clients' do
    it 'includes account_id query param when provided' do
      stub_request(:get, "#{base_url}/api/clients?account_id=5")
        .with(headers: { 'Authorization' => basic_auth_header })
        .to_return(status: 200, body: [].to_json, headers: { 'Content-Type' => 'application/json' })

      result = client.clients(account_id: 5)
      expect(result.ok?).to be true
      expect(result.data).to eq([])
    end

    it 'omits account_id when not provided' do
      stub_request(:get, "#{base_url}/api/clients")
        .to_return(status: 200, body: [].to_json, headers: { 'Content-Type' => 'application/json' })

      expect(client.clients.ok?).to be true
    end
  end

  describe '#save_client' do
    it 'returns :validation with details on 422' do
      detail_payload = { detail: [{ loc: %w[body name], msg: 'field required', type: 'value_error.missing' }] }
      stub_request(:put, "#{base_url}/api/clients/foo")
        .to_return(status: 422, body: detail_payload.to_json, headers: { 'Content-Type' => 'application/json' })

      result = client.save_client('foo', { invalid: 1 })
      expect(result.failure?).to be true
      expect(result.kind).to eq(:validation)
      expect(result.details).to be_a(Hash)
      expect(result.details['detail']).to be_an(Array)
    end
  end

  describe '#client (single)' do
    it 'returns :not_found on 404' do
      stub_request(:get, "#{base_url}/api/clients/nope")
        .to_return(status: 404, body: { detail: 'not found' }.to_json, headers: { 'Content-Type' => 'application/json' })

      result = client.client('nope')
      expect(result.failure?).to be true
      expect(result.kind).to eq(:not_found)
    end
  end

  describe 'connection errors' do
    it 'returns :agentic_offline on connection refused' do
      stub_request(:get, "#{base_url}/api/health").to_raise(Faraday::ConnectionFailed.new('connection refused'))

      result = client.health
      expect(result.failure?).to be true
      expect(result.kind).to eq(:agentic_offline)
    end
  end

  describe 'auth errors' do
    it 'returns :unauthorized on 401' do
      stub_request(:get, "#{base_url}/api/health")
        .to_return(status: 401, body: { detail: 'bad creds' }.to_json, headers: { 'Content-Type' => 'application/json' })

      result = client.health
      expect(result.failure?).to be true
      expect(result.kind).to eq(:unauthorized)
    end
  end

  describe 'server errors' do
    it 'returns :server_error on 500' do
      stub_request(:get, "#{base_url}/api/health")
        .to_return(status: 500, body: { detail: 'boom' }.to_json, headers: { 'Content-Type' => 'application/json' })

      result = client.health
      expect(result.failure?).to be true
      expect(result.kind).to eq(:server_error)
    end
  end

  describe '#extract_message' do
    it 'returns nil when detail is an Array (FastAPI 422 shape)' do
      body = { 'detail' => [{ 'loc' => %w[body name], 'msg' => 'field required', 'type' => 'value_error.missing' }] }
      expect(client.send(:extract_message, body)).to be_nil
    end

    it 'returns nil when detail is a Hash' do
      body = { 'detail' => { 'code' => 'x', 'message' => 'y' } }
      expect(client.send(:extract_message, body)).to be_nil
    end

    it 'returns the string when detail is a String' do
      expect(client.send(:extract_message, { 'detail' => 'boom' })).to eq('boom')
    end

    it 'falls back to message and error keys' do
      expect(client.send(:extract_message, { 'message' => 'm' })).to eq('m')
      expect(client.send(:extract_message, { 'error' => 'e' })).to eq('e')
    end
  end

  describe 'fallback failure with non-string detail' do
    it 'uses generic message when detail is an Array on a 500' do
      body = { detail: [{ loc: %w[body name], msg: 'oops' }] }
      stub_request(:get, "#{base_url}/api/health")
        .to_return(status: 500, body: body.to_json, headers: { 'Content-Type' => 'application/json' })

      result = client.health
      expect(result.failure?).to be true
      expect(result.kind).to eq(:server_error)
      expect(result.message).to eq('Server error (500)')
    end
  end

  describe 'basic auth header' do
    it 'is present in every request' do
      stub_health = stub_request(:get, "#{base_url}/api/health")
                    .with(headers: { 'Authorization' => basic_auth_header })
                    .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })
      stub_templates = stub_request(:get, "#{base_url}/api/templates")
                       .with(headers: { 'Authorization' => basic_auth_header })
                       .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })
      stub_delete = stub_request(:delete, "#{base_url}/api/clients/foo")
                    .with(headers: { 'Authorization' => basic_auth_header })
                    .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

      client.health
      client.templates
      client.delete_client('foo')

      expect(stub_health).to have_been_requested
      expect(stub_templates).to have_been_requested
      expect(stub_delete).to have_been_requested
    end
  end
end
