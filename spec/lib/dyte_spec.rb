require 'rails_helper'

describe Dyte do
  let(:dyte_client) { described_class.new('account_id', 'app_id', 'api_token') }
  let(:headers) { { 'Content-Type' => 'application/json' } }

  it 'raises an exception if account ID, app ID, or API token is absent' do
    expect { described_class.new }.to raise_error(StandardError)
  end

  context 'when create_a_meeting is called' do
    context 'when API response is success' do
      before do
        stub_request(:post, 'https://api.cloudflare.com/client/v4/accounts/account_id/realtime/kit/app_id/meetings')
          .to_return(
            status: 200,
            body: { success: true, data: { id: 'meeting_id' } }.to_json,
            headers: headers
          )
      end

      it 'returns api response' do
        response = dyte_client.create_a_meeting('title_of_the_meeting')
        expect(response).to eq({ 'id' => 'meeting_id' })
      end
    end

    context 'when API response is invalid' do
      before do
        stub_request(:post, 'https://api.cloudflare.com/client/v4/accounts/account_id/realtime/kit/app_id/meetings')
          .to_return(status: 422, body: { message: 'Title is required' }.to_json, headers: headers)
      end

      it 'returns error code with data' do
        response = dyte_client.create_a_meeting('')
        expect(response).to eq({ error: { 'message' => 'Title is required' }, error_code: 422 })
      end
    end
  end

  context 'when add_participant_to_meeting is called' do
    let(:participants_url) { 'https://api.cloudflare.com/client/v4/accounts/account_id/realtime/kit/app_id/meetings/m_id/participants' }

    context 'when API parameters are missing' do
      it 'raises an exception' do
        expect { dyte_client.add_participant_to_meeting }.to raise_error(StandardError)
      end
    end

    context 'when API response is success' do
      before do
        stub_request(:post, participants_url)
          .to_return(
            status: 200,
            body: { success: true, data: { id: 'random_uuid', token: 'json-web-token' } }.to_json,
            headers: headers
          )
      end

      it 'returns api response' do
        response = dyte_client.add_participant_to_meeting('m_id', 'c_id', 'name', 'https://avatar.url')
        expect(response).to eq({ 'id' => 'random_uuid', 'token' => 'json-web-token' })
        expect(WebMock).to(
          have_requested(:post, participants_url).with { |request| JSON.parse(request.body)['preset_name'] == 'group-call-host' }
        )
      end
    end

    context 'when API response is invalid' do
      before do
        stub_request(:post, participants_url)
          .to_return(status: 422, body: { message: 'Meeting ID is invalid' }.to_json, headers: headers)
      end

      it 'returns error code with data' do
        response = dyte_client.add_participant_to_meeting('m_id', 'c_id', 'name', 'https://avatar.url')
        expect(response).to eq({ error: { 'message' => 'Meeting ID is invalid' }, error_code: 422 })
      end
    end
  end
end
