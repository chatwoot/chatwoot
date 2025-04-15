require 'rails_helper'

RSpec.describe Crm::Leadsquared::Api::BaseClient do
  let(:access_key) { SecureRandom.hex }
  let(:secret_key) { SecureRandom.hex }
  let(:headers) do
    {
      'Content-Type': 'application/json',
      'x-LSQ-AccessKey': access_key,
      'x-LSQ-SecretKey': secret_key
    }
  end

  let(:endpoint_url) { 'https://api.leadsquared.com/v2' }
  let(:client) { described_class.new(access_key, secret_key, endpoint_url) }

  describe '#initialize' do
    it 'creates a client with valid credentials' do
      expect(client.instance_variable_get(:@access_key)).to eq(access_key)
      expect(client.instance_variable_get(:@secret_key)).to eq(secret_key)
      expect(client.instance_variable_get(:@base_uri)).to eq(endpoint_url)
    end
  end

  describe '#get' do
    let(:path) { 'LeadManagement.svc/Leads.Get' }
    let(:params) { { leadId: '123' } }
    let(:full_url) { URI.join(endpoint_url, path).to_s }

    context 'when request is successful' do
      before do
        stub_request(:get, full_url)
          .with(
            query: params,
            headers: headers
          )
          .to_return(
            status: 200,
            body: { Message: 'Success', Status: 'Success' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns success response with data' do
        response = client.get(path, params)
        expect(response[:success]).to be true
        expect(response[:data]).to include('Message' => 'Success')
      end
    end

    context 'when request returns error status' do
      before do
        stub_request(:get, full_url)
          .with(
            query: params,
            headers: headers
          )
          .to_return(
            status: 200,
            body: { Status: 'Error', ExceptionMessage: 'Invalid lead ID' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns error response' do
        response = client.get(path, params)
        expect(response[:success]).to be false
        expect(response[:error]).to eq('Invalid lead ID')
      end
    end

    context 'when request fails with non-200 status' do
      before do
        stub_request(:get, full_url)
          .with(
            query: params,
            headers: headers
          )
          .to_return(status: 404, body: 'Not Found')
      end

      it 'returns error response with status code' do
        response = client.get(path, params)
        expect(response[:success]).to be false
        expect(response[:error]).to eq('Not Found')
        expect(response[:code]).to eq(404)
      end
    end
  end

  describe '#post' do
    let(:path) { 'LeadManagement.svc/Lead.Create' }
    let(:params) { {} }
    let(:body) { { FirstName: 'John', LastName: 'Doe' } }
    let(:full_url) { URI.join(endpoint_url, path).to_s }

    context 'when request is successful' do
      before do
        stub_request(:post, full_url)
          .with(
            query: params,
            body: body.to_json,
            headers: headers
          )
          .to_return(
            status: 200,
            body: { Message: 'Lead created', Status: 'Success' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns success response with data' do
        response = client.post(path, params, body)
        expect(response[:success]).to be true
        expect(response[:data]).to include('Message' => 'Lead created')
      end
    end

    context 'when request returns error status' do
      before do
        stub_request(:post, full_url)
          .with(
            query: params,
            body: body.to_json,
            headers: headers
          )
          .to_return(
            status: 200,
            body: { Status: 'Error', ExceptionMessage: 'Invalid data' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns error response' do
        response = client.post(path, params, body)
        expect(response[:success]).to be false
        expect(response[:error]).to eq('Invalid data')
      end
    end

    context 'when response cannot be parsed' do
      before do
        stub_request(:post, full_url)
          .with(
            query: params,
            body: body.to_json,
            headers: headers
          )
          .to_return(
            status: 200,
            body: 'Invalid JSON',
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns error response for invalid JSON' do
        response = client.post(path, params, body)
        expect(response[:success]).to be false
        expect(response[:error]).to eq('Invalid response')
      end
    end

    context 'when request fails with server error' do
      before do
        stub_request(:post, full_url)
          .with(
            query: params,
            body: body.to_json,
            headers: headers
          )
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'returns error response with status code' do
        response = client.post(path, params, body)
        expect(response[:success]).to be false
        expect(response[:error]).to eq('Internal Server Error')
        expect(response[:code]).to eq(500)
      end
    end
  end
end
