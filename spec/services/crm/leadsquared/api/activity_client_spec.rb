require 'rails_helper'

RSpec.describe Crm::Leadsquared::Api::ActivityClient do
  let(:credentials) do
    {
      access_key: SecureRandom.hex,
      secret_key: SecureRandom.hex,
      endpoint_url: 'https://api.leadsquared.com/'
    }
  end

  let(:headers) do
    {
      'Content-Type': 'application/json',
      'x-LSQ-AccessKey': credentials[:access_key],
      'x-LSQ-SecretKey': credentials[:secret_key]
    }
  end
  let(:client) { described_class.new(credentials[:access_key], credentials[:secret_key], credentials[:endpoint_url]) }
  let(:prospect_id) { SecureRandom.uuid }
  let(:activity_event) { 1001 } # Example activity event code
  let(:activity_note) { 'Test activity note' }
  let(:activity_date_time) { '2025-04-11 14:15:00' }

  describe '#post_activity' do
    let(:path) { '/ProspectActivity.svc/Create' }
    let(:full_url) { URI.join(credentials[:endpoint_url], path).to_s }

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
          'Message' => {
            'Id' => activity_id,
            'Message' => 'Activity created successfully'
          }
        }
      end

      before do
        stub_request(:post, full_url)
          .with(
            body: {
              'RelatedProspectId' => prospect_id,
              'ActivityEvent' => activity_event,
              'ActivityNote' => activity_note
            }.to_json,
            headers: headers
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
        expect(response[:activity_id]).to eq(activity_id)
      end
    end

    context 'when response indicates failure' do
      let(:error_response) do
        {
          :success => false,
          :error => '{"Status":"Error","ExceptionType":"NullReferenceException","ExceptionMessage":"There was an error processing the request."}',
          :code => 500
        }
      end

      before do
        stub_request(:post, full_url)
          .with(
            body: {
              'RelatedProspectId' => prospect_id,
              'ActivityEvent' => activity_event,
              'ActivityNote' => activity_note
            }.to_json,
            headers: headers
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

  describe '#create_activity_type' do
    let(:path) { 'ProspectActivity.svc/CreateType' }
    let(:full_url) { URI.join(credentials[:endpoint_url], path).to_s }
    let(:activity_params) do
      {
        name: 'Test Activity Type',
        score: 10,
        direction: 0
      }
    end

    context 'when request is successful' do
      let(:activity_event_id) { 1001 }
      let(:success_response) do
        {
          'Status' => 'Success',
          'Message' => {
            'Id' => activity_event_id
          }
        }
      end

      before do
        stub_request(:post, full_url)
          .with(
            body: {
              'ActivityEventName' => activity_params[:name],
              'Score' => activity_params[:score],
              'Direction' => activity_params[:direction]
            }.to_json,
            headers: headers
          )
          .to_return(
            status: 200,
            body: success_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns success response with activity ID' do
        response = client.create_activity_type(**activity_params)
        expect(response[:success]).to be true
        expect(response[:activity_id]).to eq(activity_event_id)
      end
    end

    context 'when response indicates failure' do
      let(:error_response) do
        {
          :success => false,
          :error => '{"Status":"Error","ExceptionType":"MXInvalidInputException","ExceptionMessage":"Invalid Input! Parameter Name: activity"}',
          :code => 500
        }
      end

      before do
        stub_request(:post, full_url)
          .with(
            body: {
              'ActivityEventName' => activity_params[:name],
              'Score' => activity_params[:score],
              'Direction' => activity_params[:direction]
            }.to_json,
            headers: headers
          )
          .to_return(
            status: 200,
            body: error_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns error response' do
        response = client.create_activity_type(**activity_params)
        expect(response[:success]).to be false
        expect(response[:error]).to eq('Activity not created')
      end
    end

    context 'when API request fails' do
      before do
        stub_request(:post, full_url)
          .with(
            body: {
              'ActivityEventName' => activity_params[:name],
              'Score' => activity_params[:score],
              'Direction' => activity_params[:direction]
            }.to_json,
            headers: headers
          )
          .to_return(
            status: 500,
            body: 'Internal Server Error',
            headers: { 'Content-Type' => 'text/plain' }
          )
      end

      it 'returns error response' do
        response = client.create_activity_type(**activity_params)
        expect(response[:success]).to be false
        expect(response[:error]).to be_present
      end
    end
  end
end
