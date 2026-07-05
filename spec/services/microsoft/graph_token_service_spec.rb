require 'rails_helper'

RSpec.describe Microsoft::GraphTokenService do
  let(:channel) do
    create(:channel_email, :microsoft_email, provider_config: {
             access_token: SecureRandom.hex, refresh_token: SecureRandom.hex, expires_on: (Time.zone.now + 3600).to_s
           })
  end
  let(:graph_response) { { access_token: SecureRandom.hex, expires_in: 3599 } }

  it 'exchanges the refresh token for a Graph token on the /common endpoint by default' do
    common_request = stub_request(:post, 'https://login.microsoftonline.com/common/oauth2/v2.0/token')
                     .with(body: hash_including('grant_type' => 'refresh_token', 'scope' => Microsoft::Scopes::GRAPH))
                     .to_return(status: 200, body: graph_response.to_json, headers: { 'Content-Type' => 'application/json' })

    token = described_class.new(channel: channel).access_token

    expect(common_request).to have_been_requested
    expect(token).to eq(graph_response[:access_token])
  end

  it 'requests a calendar-capable Graph token when the mailbox is calendar-enabled' do
    channel.update!(calendar_enabled: true)
    calendar_request = stub_request(:post, 'https://login.microsoftonline.com/common/oauth2/v2.0/token')
                       .with(body: hash_including('scope' => Microsoft::Scopes::GRAPH_WITH_CALENDAR))
                       .to_return(status: 200, body: graph_response.to_json, headers: { 'Content-Type' => 'application/json' })

    described_class.new(channel: channel).access_token

    expect(calendar_request).to have_been_requested
  end

  it 'keeps the mail-only Graph scope for a mailbox without calendar access' do
    channel.update!(calendar_enabled: false)
    mail_only_request = stub_request(:post, 'https://login.microsoftonline.com/common/oauth2/v2.0/token')
                        .with(body: hash_including('scope' => Microsoft::Scopes::GRAPH))
                        .to_return(status: 200, body: graph_response.to_json, headers: { 'Content-Type' => 'application/json' })

    described_class.new(channel: channel).access_token

    expect(mail_only_request).to have_been_requested
  end

  it 'uses the tenant-specific endpoint when the channel account has a tenant_id' do
    tenant = 'a1b2c3d4-1111-2222-3333-444455556666'
    channel.account.email_oauth_apps.create!(
      provider: 'microsoft', client_id: SecureRandom.uuid, client_secret: SecureRandom.hex(20), tenant_id: tenant
    )
    tenant_request = stub_request(:post, "https://login.microsoftonline.com/#{tenant}/oauth2/v2.0/token")
                     .with(body: hash_including('grant_type' => 'refresh_token'))
                     .to_return(status: 200, body: graph_response.to_json, headers: { 'Content-Type' => 'application/json' })

    described_class.new(channel: channel).access_token

    expect(tenant_request).to have_been_requested
  end

  it 'raises a stable error code without leaking the provider error description' do
    stub_request(:post, 'https://login.microsoftonline.com/common/oauth2/v2.0/token').to_return(status: 400, body: {
      error: 'invalid_grant', error_description: 'AADSTS9002313: secret details here'
    }.to_json)

    expect do
      described_class.new(channel: channel).access_token
    end.to raise_error(StandardError, 'graph_token_refresh_failed (400)')
  end
end
