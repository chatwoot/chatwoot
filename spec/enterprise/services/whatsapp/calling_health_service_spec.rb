require 'rails_helper'

RSpec.describe Whatsapp::CallingHealthService do
  subject(:result) { described_class.new(channel: channel).perform }

  let(:channel) do
    create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
  end
  let(:graph) { 'https://graph.facebook.com/v22.0' }
  let(:headers) { { 'Content-Type' => 'application/json' } }
  let(:app_id) { 'chatwoot-app' }
  let(:app_secret) { 'chatwoot-secret' }
  let(:calling) { { 'status' => 'ENABLED' } }
  let(:subscribed_app_id) { app_id }
  let(:waba_fields) { %w[messages calls] }

  before do
    create(:installation_config, name: 'WHATSAPP_APP_ID', value: 'chatwoot-app')
    create(:installation_config, name: 'WHATSAPP_APP_SECRET', value: 'chatwoot-secret')
    stub_request(:get, "#{graph}/123456789/settings").to_return(status: 200, headers: headers, body: { calling: calling }.to_json)
    stub_request(:get, "#{graph}/123456789/subscribed_apps").to_return(
      status: 200, headers: headers, body: { data: [{ whatsapp_business_api_data: { id: subscribed_app_id } }] }.to_json
    )
    stub_request(:get, "#{graph}/#{app_id}/subscriptions")
      .with(headers: { 'Authorization' => "Bearer #{app_id}|#{app_secret}" })
      .to_return(status: 200, headers: headers, body: { data: [
        { object: 'whatsapp_business_account', active: true, fields: waba_fields.map { |name| { name: name } } }
      ] }.to_json)
  end

  it 'reports a fully set up number as healthy' do
    expect(result).to eq(
      meta_status: { status: 'enabled' },
      webhook_subscription: { status: 'configured' },
      eligibility: { status: 'eligible', restrictions: [] }
    )
  end

  context 'when Meta has calling disabled and restricted' do
    let(:calling) do
      {
        'status' => 'DISABLED',
        'restrictions' => { 'restrictions_list' => [{ 'type' => 'RESTRICTED_USER_INITIATED_CALLING', 'expiration' => 1_800_000_000 }] }
      }
    end

    it 'reports both' do
      expect(result[:meta_status]).to eq(status: 'disabled')
      expect(result[:eligibility]).to eq(
        status: 'restricted',
        restrictions: [{ type: 'RESTRICTED_USER_INITIATED_CALLING', expires_at: Time.zone.at(1_800_000_000).iso8601 }]
      )
    end
  end

  context 'when the call settings fail to load' do
    before { stub_request(:get, "#{graph}/123456789/settings").to_return(status: 500, body: '{}') }

    it 'marks only the settings-based checks unverified' do
      expect(result).to eq(
        meta_status: { status: 'unverified' },
        webhook_subscription: { status: 'configured' },
        eligibility: { status: 'unverified' }
      )
    end
  end

  context 'when the app is not subscribed to the WABA' do
    let(:subscribed_app_id) { 'some-other-app' }

    it 'reports the missing app subscription' do
      expect(result[:webhook_subscription]).to eq(status: 'missing', reason: 'app_not_subscribed')
    end
  end

  context 'when the app does not subscribe to the calls field' do
    let(:waba_fields) { %w[messages] }

    it 'reports the missing calls field' do
      expect(result[:webhook_subscription]).to eq(status: 'missing', reason: 'calls_field_missing')
    end
  end

  context 'with a manually set up inbox' do
    let(:app_id) { 'customer-app' }
    let(:app_secret) { 'customer-secret' }

    before do
      channel.provider_config = channel.provider_config.merge('source' => 'manual', 'app_secret' => app_secret)
      stub_request(:get, "#{graph}/app").to_return(status: 200, headers: headers, body: { id: app_id }.to_json)
    end

    it "checks the customer's own app" do
      expect(result[:webhook_subscription]).to eq(status: 'configured')
    end
  end
end
