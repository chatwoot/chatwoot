require 'rails_helper'

RSpec.describe 'Bandwidth inbox configuration', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:headers) { admin.create_new_auth_token }
  let(:channel) { create(:channel_sms, account: account) }
  let(:inbox) { channel.inbox }
  let(:url) { "/api/v1/accounts/#{account.id}/inboxes" }
  let(:oauth_config) { { account_id: '123', application_id: 'app', client_id: 'client', client_secret: 'secret' } }
  let(:token_service) { instance_double(Sms::BandwidthTokenService, token: 'token') }

  before { allow(Sms::BandwidthTokenService).to receive(:new).and_return(token_service) }

  [nil, {}, { api_key: 'legacy', api_secret: 'secret' }, { client_id: 'client' }].each do |config|
    it "rejects new inboxes without complete OAuth credentials: #{config.inspect}" do
      params = { name: 'Bandwidth', channel: { type: 'sms', phone_number: '+15551234567' } }
      params[:channel][:provider_config] = config unless config.nil?
      expect { post url, headers: headers, params: params, as: :json }.not_to change(Channel::Sms, :count)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(token_service).not_to have_received(:token)
    end
  end

  it 'verifies OAuth when creating an inbox and omits the secret from its response' do
    post url, headers: headers,
              params: { name: 'Bandwidth', channel: { type: 'sms', phone_number: '+15551234567', provider_config: oauth_config } }, as: :json
    expect(response).to have_http_status(:ok)
    expect(token_service).to have_received(:token).with(force: true)
    expect(response.parsed_body['provider_config']).to eq(oauth_config.stringify_keys.except('client_secret'))
  end

  it 'merges migration credentials while preserving the inbox and existing configuration' do
    original = channel.provider_config.dup
    patch "#{url}/#{inbox.id}", headers: headers,
                                params: { channel: { provider_config: oauth_config.slice(:client_id, :client_secret) } }, as: :json
    expect(response).to have_http_status(:ok)
    expect(channel.reload.provider_config).to eq(original.merge('client_id' => 'client', 'client_secret' => 'secret'))
    expect(response.parsed_body['id']).to eq(inbox.id)
    expect(response.parsed_body['bandwidth_oauth_enabled']).to be(true)
    expect(response.parsed_body['provider_config'].keys).to match_array(%w[account_id application_id client_id])
  end

  it 'preserves legacy configuration when verification rejects credentials' do
    allow(token_service).to receive(:token).and_raise(CustomExceptions::Bandwidth::AuthenticationError.new)
    expect do
      patch "#{url}/#{inbox.id}", headers: headers, params: { channel: { provider_config: oauth_config } }, as: :json
    end.not_to(change { channel.reload.provider_config })
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'returns a retryable error without saving credentials when the token service is unavailable' do
    allow(token_service).to receive(:token).and_raise(CustomExceptions::Bandwidth::TokenRequestError.new)
    expect do
      patch "#{url}/#{inbox.id}", headers: headers, params: { channel: { provider_config: oauth_config } }, as: :json
    end.not_to(change { channel.reload.provider_config })
    expect(response).to have_http_status(:service_unavailable)
  end

  it 'allows existing legacy configuration updates without requiring OAuth' do
    patch "#{url}/#{inbox.id}", headers: headers, params: { channel: { provider_config: channel.provider_config } }, as: :json
    expect(response).to have_http_status(:ok)
    expect(channel.reload.oauth?).to be(false)
    expect(token_service).not_to have_received(:token)
  end
end
