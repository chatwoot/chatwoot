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

    context 'when API response succeeds without data' do
      before do
        stub_request(:post, 'https://api.cloudflare.com/client/v4/accounts/account_id/realtime/kit/app_id/meetings')
          .to_return(status: 200, body: { success: true, data: nil }.to_json, headers: headers)
      end

      it 'returns an explicit unexpected response error' do
        response = dyte_client.create_a_meeting('title_of_the_meeting')
        expect(response).to eq({ error: :unexpected_response, error_code: 200 })
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

    context 'when the default preset is not found' do
      before do
        stub_request(:post, participants_url)
          .with { |request| JSON.parse(request.body)['preset_name'] == 'group-call-host' }
          .to_return(
            status: 404,
            body: { success: false, error: { code: 404, message: 'ResourceNotFound: No preset found with name group-call-host' } }.to_json,
            headers: headers
          )

        stub_request(:post, participants_url)
          .with { |request| JSON.parse(request.body)['preset_name'] == 'group_call_host' }
          .to_return(
            status: 200,
            body: { success: true, data: { id: 'random_uuid', token: 'json-web-token' } }.to_json,
            headers: headers
          )
      end

      it 'retries with the legacy Dyte preset name' do
        response = dyte_client.add_participant_to_meeting('m_id', 'c_id', 'name', 'https://avatar.url')

        expect(response).to eq({ 'id' => 'random_uuid', 'token' => 'json-web-token' })
      end
    end
  end

  context 'when refresh_participant_token is called' do
    let(:participant_token_url) do
      'https://api.cloudflare.com/client/v4/accounts/account_id/realtime/kit/app_id/meetings/m_id/participants/participant_id/token'
    end

    context 'when API response is success' do
      before do
        stub_request(:post, participant_token_url)
          .to_return(status: 200, body: { success: true, data: { token: 'refreshed-json-web-token' } }.to_json, headers: headers)
      end

      it 'returns a refreshed participant token' do
        response = dyte_client.refresh_participant_token('m_id', 'participant_id')

        expect(response).to eq({ 'token' => 'refreshed-json-web-token' })
      end
    end

    context 'when API parameters are missing' do
      it 'raises an exception' do
        expect { dyte_client.refresh_participant_token('m_id', nil) }.to raise_error(StandardError)
      end
    end
  end

  context 'when fetch_participants is called' do
    let(:participants_url) { 'https://api.cloudflare.com/client/v4/accounts/account_id/realtime/kit/app_id/meetings/m_id/participants' }

    context 'when API response is success' do
      before do
        stub_request(:get, participants_url)
          .to_return(
            status: 200,
            body: { success: true, data: [{ id: 'participant_id', custom_participant_id: 'c_id' }] }.to_json,
            headers: headers
          )
      end

      it 'returns participants' do
        response = dyte_client.fetch_participants('m_id')

        expect(response).to eq([{ 'id' => 'participant_id', 'custom_participant_id' => 'c_id' }])
      end
    end

    context 'when API parameters are missing' do
      it 'raises an exception' do
        expect { dyte_client.fetch_participants(nil) }.to raise_error(StandardError)
      end
    end
  end
end
