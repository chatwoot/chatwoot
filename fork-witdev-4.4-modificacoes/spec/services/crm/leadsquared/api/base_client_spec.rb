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

      it 'returns parsed response data directly' do
        response = client.get(path, params)
        expect(response).to include('Message' => 'Success')
        expect(response).to include('Status' => 'Success')
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

      it 'raises ApiError with error message' do
        expect { client.get(path, params) }.to raise_error(
          Crm::Leadsquared::Api::BaseClient::ApiError,
          'Invalid lead ID'
        )
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

      it 'raises ApiError with status code' do
        expect { client.get(path, params) }.to raise_error do |error|
          expect(error).to be_a(Crm::Leadsquared::Api::BaseClient::ApiError)
          expect(error.message).to include('Not Found')
          expect(error.code).to eq(404)
        end
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

      it 'returns parsed response data directly' do
        response = client.post(path, params, body)
        expect(response).to include('Message' => 'Lead created')
        expect(response).to include('Status' => 'Success')
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

      it 'raises ApiError with error message' do
        expect { client.post(path, params, body) }.to raise_error(
          Crm::Leadsquared::Api::BaseClient::ApiError,
          'Invalid data'
        )
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

      it 'raises ApiError for invalid JSON' do
        expect { client.post(path, params, body) }.to raise_error do |error|
          expect(error).to be_a(Crm::Leadsquared::Api::BaseClient::ApiError)
          expect(error.message).to include('Failed to parse')
        end
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

      it 'raises ApiError with status code' do
        expect { client.post(path, params, body) }.to raise_error do |error|
          expect(error).to be_a(Crm::Leadsquared::Api::BaseClient::ApiError)
          expect(error.message).to include('Internal Server Error')
          expect(error.code).to eq(500)
        end
      end
    end
  end
end
