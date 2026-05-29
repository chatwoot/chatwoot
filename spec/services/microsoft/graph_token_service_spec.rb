require 'rails_helper'

describe Microsoft::GraphTokenService do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_email, :microsoft_email, account: account) }
  let(:service) { described_class.new(channel: channel) }

  describe '#access_token' do
    let(:token_response_body) { { 'access_token' => 'graph-api-token-123' }.to_json }

    before do
      allow(GlobalConfigService).to receive(:load).with('AZURE_APP_ID', '').and_return('test-app-id')
      allow(GlobalConfigService).to receive(:load).with('AZURE_APP_SECRET', '').and_return('test-app-secret')
    end

    context 'when token refresh succeeds' do
      before do
        stub_request(:post, 'https://login.microsoftonline.com/common/oauth2/v2.0/token')
          .to_return(status: 200, body: token_response_body, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns the access token from Microsoft' do
        expect(service.access_token).to eq('graph-api-token-123')
      end

      it 'sends the correct parameters' do
        service.access_token

        expect(WebMock).to have_requested(:post, 'https://login.microsoftonline.com/common/oauth2/v2.0/token')
          .with(body: hash_including(
            'client_id' => 'test-app-id',
            'client_secret' => 'test-app-secret',
            'grant_type' => 'refresh_token',
            'scope' => 'https://graph.microsoft.com/Mail.Send https://graph.microsoft.com/Mail.ReadWrite offline_access'
          ))
      end
    end

    context 'when token refresh fails' do
      before do
        stub_request(:post, 'https://login.microsoftonline.com/common/oauth2/v2.0/token')
          .to_return(
            status: 400,
            body: { 'error' => 'invalid_grant', 'error_description' => 'Token has expired' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises an error with the failure message' do
        expect { service.access_token }.to raise_error(StandardError, /Token has expired/)
      end
    end
  end
end
