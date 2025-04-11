require 'rails_helper'

RSpec.describe Crm::Leadsquared::Api::LeadClient do
  let(:access_key) { SecureRandom.hex }
  let(:secret_key) { SecureRandom.hex }
  let(:endpoint_url) { 'https://api.leadsquared.com/' }
  let(:client) { described_class.new(access_key, secret_key, endpoint_url) }

  describe '#search_lead' do
    let(:path) { '/v2/LeadManagement.svc/Leads.GetByQuickSearch' }
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
          .with(query: { accessKey: access_key, secretKey: secret_key, key: search_key })
          .to_return(
            status: 200,
            body: [].to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns success with nil data' do
        response = client.search_lead(search_key)
        expect(response[:success]).to be true
        expect(response[:data]).to be_nil
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
          .with(query: { accessKey: access_key, secretKey: secret_key, key: search_key })
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
    let(:path) { '/v2/LeadManagement.svc/Lead.CreateOrUpdate' }
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
          'Value' => {
            'Message' => 'Lead created successfully',
            'ProspectId' => SecureRandom.uuid,
            'AffectedRows' => 1
          }
        }
      end

      before do
        stub_request(:post, full_url)
          .with(
            query: { accessKey: access_key, secretKey: secret_key },
            body: formatted_lead_data.to_json,
            headers: { 'Content-Type' => 'application/json' }
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
        expect(response[:data]).to eq(success_response['Value'])
      end
    end

    context 'when no leads are affected' do
      let(:no_affect_response) do
        {
          'Status' => 'Success',
          'Value' => {
            'Message' => 'No changes required',
            'AffectedRows' => 0
          }
        }
      end

      before do
        stub_request(:post, full_url)
          .with(
            query: { accessKey: access_key, secretKey: secret_key },
            body: formatted_lead_data.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
          .to_return(
            status: 200,
            body: no_affect_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns error indicating no leads affected' do
        response = client.create_or_update_lead(lead_data)
        expect(response[:success]).to be false
        expect(response[:error]).to eq('No leads created or updated')
      end
    end

    context 'when request fails' do
      let(:error_response) do
        {
          'Status' => 'Error',
          'ExceptionMessage' => 'Invalid lead data'
        }
      end

      before do
        stub_request(:post, full_url)
          .with(
            query: { accessKey: access_key, secretKey: secret_key },
            body: formatted_lead_data.to_json,
            headers: { 'Content-Type' => 'application/json' }
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
        expect(response[:error]).to eq('Invalid lead data')
      end
    end
  end
end
