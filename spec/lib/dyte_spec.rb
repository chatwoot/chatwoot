require 'rails_helper'

describe Dyte do
  let(:dyte_client) { described_class.new('org_id', 'api_key') }
  let(:headers) { { 'Content-Type' => 'application/json' } }

  it 'raises an exception if api_key or organization ID is absent' do
    expect { described_class.new }.to raise_error(StandardError)
  end

  context 'when create_a_meeting is called' do
    context 'when API response is success' do
      before do
        stub_request(:post, 'https://api.cluster.dyte.in/v1/organizations/org_id/meeting')
          .to_return(
            status: 200,
            body: { success: true, data: { meeting: { id: 'meeting_id' } } }.to_json,
            headers: headers
          )
      end

      it 'returns api response' do
        response = dyte_client.create_a_meeting('title_of_the_meeting')
        expect(response).to eq({ 'meeting' => { 'id' => 'meeting_id' } })
      end
    end

    context 'when API response is invalid' do
      before do
        stub_request(:post, 'https://api.cluster.dyte.in/v1/organizations/org_id/meeting')
          .to_return(status: 422, body: { message: 'Title is required' }.to_json, headers: headers)
      end

      it 'returns error code with data' do
        response = dyte_client.create_a_meeting('')
        expect(response).to eq({ error: { 'message' => 'Title is required' }, error_code: 422 })
      end
    end
  end

  context 'when add_participant_to_meeting is called' do
    context 'when API parameters are missing' do
      it 'raises an exception' do
        expect { dyte_client.add_participant_to_meeting }.to raise_error(StandardError)
      end
    end

    context 'when API response is success' do
      before do
        stub_request(:post, 'https://api.cluster.dyte.in/v1/organizations/org_id/meetings/m_id/participant')
          .to_return(
            status: 200,
            body: { success: true, data: { authResponse: { userAdded: true, id: 'random_uuid', auth_token: 'json-web-token' } } }.to_json,
            headers: headers
          )
      end

      it 'returns api response' do
        response = dyte_client.add_participant_to_meeting('m_id', 'c_id', 'name', 'https://avatar.url')
        expect(response).to eq({ 'authResponse' => { 'userAdded' => true, 'id' => 'random_uuid', 'auth_token' => 'json-web-token' } })
      end
    end

    context 'when API response is invalid' do
      before do
        stub_request(:post, 'https://api.cluster.dyte.in/v1/organizations/org_id/meetings/m_id/participant')
          .to_return(status: 422, body: { message: 'Meeting ID is invalid' }.to_json, headers: headers)
      end

      it 'returns error code with data' do
        response = dyte_client.add_participant_to_meeting('m_id', 'c_id', 'name', 'https://avatar.url')
        expect(response).to eq({ error: { 'message' => 'Meeting ID is invalid' }, error_code: 422 })
      end
    end
  end
end
