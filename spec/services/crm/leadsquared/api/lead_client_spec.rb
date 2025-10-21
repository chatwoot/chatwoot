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
      it 'raises ArgumentError' do
        expect { client.search_lead(nil) }
          .to raise_error(ArgumentError, 'Search key is required')
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

      it 'returns empty array directly' do
        response = client.search_lead(search_key)
        expect(response).to eq([])
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

      it 'returns lead data array directly' do
        response = client.search_lead(search_key)
        expect(response).to eq(lead_data)
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
      it 'raises ArgumentError' do
        expect { client.create_or_update_lead(nil) }
          .to raise_error(ArgumentError, 'Lead data is required')
      end
    end

    context 'when lead is successfully created' do
      let(:lead_id) { '8e0f69ae-e2ac-40fc-a0cf-827326181c8a' }
      let(:success_response) do
        {
          'Status' => 'Success',
          'Message' => {
            'Id' => lead_id
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

      it 'returns lead ID directly' do
        response = client.create_or_update_lead(lead_data)
        expect(response).to eq(lead_id)
      end
    end

    context 'when request fails' do
      let(:error_response) do
        {
          'Status' => 'Error',
          'ExceptionMessage' => 'Error message'
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
            body: error_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises ApiError' do
        expect { client.create_or_update_lead(lead_data) }
          .to raise_error(Crm::Leadsquared::Api::BaseClient::ApiError)
      end
    end

    # Add test for update_lead method
    describe '#update_lead' do
      let(:path) { 'LeadManagement.svc/Lead.Update' }
      let(:lead_id) { '8e0f69ae-e2ac-40fc-a0cf-827326181c8a' }
      let(:full_url) { URI.join(endpoint_url, "#{path}?leadId=#{lead_id}").to_s }

      context 'with missing parameters' do
        it 'raises ArgumentError when lead_id is missing' do
          expect { client.update_lead(lead_data, nil) }
            .to raise_error(ArgumentError, 'Lead ID is required')
        end

        it 'raises ArgumentError when lead_data is missing' do
          expect { client.update_lead(nil, lead_id) }
            .to raise_error(ArgumentError, 'Lead data is required')
        end
      end

      context 'when update is successful' do
        let(:success_response) do
          {
            'Status' => 'Success',
            'Message' => {
              'AffectedRows' => 1
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

        it 'returns affected rows directly' do
          response = client.update_lead(lead_data, lead_id)
          expect(response).to eq(1)
        end
      end

      context 'when update fails' do
        let(:error_response) do
          {
            'Status' => 'Error',
            'ExceptionMessage' => 'Invalid lead ID'
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
              body: error_response.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'raises ApiError' do
          expect { client.update_lead(lead_data, lead_id) }
            .to raise_error(Crm::Leadsquared::Api::BaseClient::ApiError)
        end
      end
    end
  end
end
