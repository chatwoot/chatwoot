require 'rails_helper'

RSpec.describe Crm::Leadsquared::Api::LeadClient do
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

  describe '#search_lead' do
    let(:path) { 'LeadManagement.svc/Leads.GetByQuickSearch' }
    let(:search_key) { 'test@example.com' }
    let(:full_url) { URI.join(endpoint_url, path).to_s }

    context 'when search key is missing' do
      it 'returns error' do
        response = client.search_lead(nil)
        expect(response[:success]).to be false
        expect(response[:error]).to eq('Search key is required')
      end
    end

    context 'when no leads are found' do
      before do
        stub_request(:get, full_url)
          .with(query: { key: search_key }, headers: headers)
          .to_return(
            status: 200,
            body: [].to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns success with [] data' do
        response = client.search_lead(search_key)
        expect(response[:success]).to be true
        expect(response[:data]).to eq([])
      end
    end

    context 'when leads are found' do
      let(:lead_data) do
        [{
          'ProspectID' => SecureRandom.uuid,
          'FirstName' => 'John',
          'LastName' => 'Doe',
          'EmailAddress' => search_key
        }]
      end

      before do
        stub_request(:get, full_url)
          .with(query: { key: search_key }, headers: headers, body: anything)
          .to_return(
            status: 200,
            body: lead_data.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns success with lead data' do
        response = client.search_lead(search_key)
        expect(response[:success]).to be true
        expect(response[:data]).to eq(lead_data)
      end
    end
  end

  describe '#create_or_update_lead' do
    let(:path) { 'LeadManagement.svc/Lead.CreateOrUpdate' }
    let(:full_url) { URI.join(endpoint_url, path).to_s }
    let(:lead_data) do
      {
        'FirstName' => 'John',
        'LastName' => 'Doe',
        'EmailAddress' => 'john.doe@example.com'
      }
    end
    let(:formatted_lead_data) do
      lead_data.map do |key, value|
        {
          'Attribute' => key,
          'Value' => value
        }
      end
    end

    context 'when lead data is missing' do
      it 'returns error' do
        response = client.create_or_update_lead(nil)
        expect(response[:success]).to be false
        expect(response[:error]).to eq('Lead data is required')
      end
    end

    context 'when lead is successfully created' do
      let(:success_response) do
        {
          'Status' => 'Success',
          'Message' => {
            'Id' => '8e0f69ae-e2ac-40fc-a0cf-827326181c8a'
          }
        }
      end

      before do
        stub_request(:post, full_url)
          .with(
            body: formatted_lead_data.to_json,
            headers: headers
          )
          .to_return(
            status: 200,
            body: success_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns success with lead data' do
        response = client.create_or_update_lead(lead_data)
        expect(response[:success]).to be true
        expect(response[:data]).to eq(success_response['Message'])
      end
    end

    context 'when request fails' do
      let(:error_response) do
        { :success => false, :error => 'Error message', :code => 404 }
      end

      before do
        stub_request(:post, full_url)
          .with(
            body: formatted_lead_data.to_json,
            headers: headers
          )
          .to_return(
            status: 200,
            body: error_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns error response' do
        response = client.create_or_update_lead(lead_data)
        expect(response[:success]).to be false
        expect(response[:error]).to eq('No leads created or updated')
      end
    end
  end
end
