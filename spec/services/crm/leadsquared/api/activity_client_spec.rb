require 'rails_helper'

RSpec.describe Crm::Leadsquared::Api::ActivityClient do
  let(:access_key) { SecureRandom.hex }
  let(:secret_key) { SecureRandom.hex }
  let(:endpoint_url) { 'https://api.leadsquared.com/' }
  let(:client) { described_class.new(access_key, secret_key, endpoint_url) }
  let(:prospect_id) { SecureRandom.uuid }
  let(:activity_event) { 1001 } # Example activity event code
  let(:activity_note) { 'Test activity note' }
  let(:activity_date_time) { '2025-04-11 14:15:00' }

  describe '#post_activity' do
    let(:path) { '/v2/ProspectActivity.svc/Create' }
    let(:full_url) { URI.join(endpoint_url, path).to_s }

    context 'with missing required parameters' do
      it 'returns error when prospect_id is missing' do
        response = client.post_activity(nil, activity_event, activity_note)
        expect(response[:success]).to be false
        expect(response[:error]).to eq('Prospect ID is required')
      end

      it 'returns error when activity_event is missing' do
        response = client.post_activity(prospect_id, nil, activity_note)
        expect(response[:success]).to be false
        expect(response[:error]).to eq('Activity event code is required')
      end
    end

    context 'when request is successful' do
      let(:activity_id) { SecureRandom.uuid }
      let(:success_response) do
        {
          'Status' => 'Success',
          'Value' => {
            'Id' => activity_id,
            'Message' => 'Activity created successfully'
          }
        }
      end

      before do
        stub_request(:post, full_url)
          .with(
            query: { accessKey: access_key, secretKey: secret_key },
            body: {
              'RelatedProspectId' => prospect_id,
              'ActivityEvent' => activity_event,
              'ActivityNote' => activity_note
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
          .to_return(
            status: 200,
            body: success_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns success response with activity data' do
        response = client.post_activity(prospect_id, activity_event, activity_note)
        expect(response[:success]).to be true
        expect(response[:data]).to eq(success_response['Value'])
      end
    end

    context 'when request includes activity_date_time' do
      let(:activity_id) { SecureRandom.uuid }
      let(:success_response) do
        {
          'Status' => 'Success',
          'Value' => {
            'Id' => activity_id,
            'Message' => 'Activity created successfully'
          }
        }
      end

      before do
        stub_request(:post, full_url)
          .with(
            query: { accessKey: access_key, secretKey: secret_key },
            body: {
              'RelatedProspectId' => prospect_id,
              'ActivityEvent' => activity_event,
              'ActivityNote' => activity_note,
              'ActivityDateTime' => activity_date_time
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
          .to_return(
            status: 200,
            body: success_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'includes activity_date_time in request' do
        response = client.post_activity(prospect_id, activity_event, activity_note, activity_date_time)
        expect(response[:success]).to be true
        expect(response[:data]).to eq(success_response['Value'])
      end
    end

    context 'when response indicates failure' do
      let(:error_response) do
        {
          'Status' => 'Success',
          'Value' => {
            'Message' => 'Activity creation failed'
          }
        }
      end

      before do
        stub_request(:post, full_url)
          .with(
            query: { accessKey: access_key, secretKey: secret_key },
            body: {
              'RelatedProspectId' => prospect_id,
              'ActivityEvent' => activity_event,
              'ActivityNote' => activity_note
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
          .to_return(
            status: 200,
            body: error_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns error response when activity ID is missing' do
        response = client.post_activity(prospect_id, activity_event, activity_note)
        expect(response[:success]).to be false
        expect(response[:error]).to eq('Activity not created')
      end
    end
  end
end
