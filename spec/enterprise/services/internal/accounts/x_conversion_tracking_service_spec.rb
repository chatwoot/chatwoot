# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Internal::Accounts::XConversionTrackingService do
  let(:account) { create(:account) }
  let(:occurred_at) { Time.zone.parse('2026-11-05T10:05:00Z') }
  let(:api_url) { 'https://ads-api.x.com/12/measurement/conversions/o1abc' }
  let(:config) do
    {
      'pixel_id' => 'o1abc',
      'consumer_key' => 'consumer-key', 'consumer_secret' => 'consumer-secret',
      'access_token' => 'access-token', 'access_token_secret' => 'access-token-secret',
      'events' => {
        'cloud_signup' => { 'event_id' => 'tw-o1abc-signup' },
        'cloud_plan_activation' => { 'event_id' => 'tw-o1abc-activation' }
      }
    }
  end
  let(:marketing_attribution) do
    {
      'first_touch' => { 'source' => 'x', 'twclid' => 'x-click-first' },
      'last_touch' => { 'source' => 'x', 'twclid' => 'x-click-last' }
    }
  end

  before do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
    create(:installation_config, name: described_class::CONFIG_KEY, value: config.to_json)
    account.update!(internal_attributes: { 'marketing_attribution' => marketing_attribution })
    stub_request(:post, api_url).to_return(status: 200, body: { data: {} }.to_json)
  end

  def sent_conversion
    body = nil
    expect(a_request(:post, api_url).with { |request| body = JSON.parse(request.body) }).to have_been_made.once
    body['conversions'].first
  end

  it 'sends the signup with the last-touch twclid, a stable conversion id and an OAuth 1.0a signature' do
    described_class.new(account: account, event_name: 'cloud_signup', occurred_at: occurred_at).perform

    expect(a_request(:post, api_url).with { |request| request.headers['Authorization'].include?('oauth_consumer_key="consumer-key"') })
      .to have_been_made.once
    expect(sent_conversion).to eq(
      'conversion_id' => "cloud_signup-account-#{account.id}",
      'conversion_time' => '2026-11-05T10:05:00.000Z',
      'event_id' => 'tw-o1abc-signup',
      'identifiers' => [{ 'twclid' => 'x-click-last' }]
    )
  end

  it 'sends the plan activation with its value, like the Google upload' do
    described_class.new(account: account, event_name: 'cloud_plan_activation', occurred_at: occurred_at,
                        conversion_value: 19.0, currency_code: 'USD').perform

    expect(sent_conversion).to include('event_id' => 'tw-o1abc-activation', 'value' => 19.0, 'price_currency' => 'USD')
  end

  it 'falls back to the first-touch twclid' do
    marketing_attribution['last_touch'] = { 'source' => 'google', 'gclid' => 'g-click' }
    account.update!(internal_attributes: { 'marketing_attribution' => marketing_attribution })

    described_class.new(account: account, event_name: 'cloud_signup').perform

    expect(sent_conversion['identifiers']).to eq([{ 'twclid' => 'x-click-first' }])
  end

  it 'sends nothing without a twclid' do
    account.update!(internal_attributes: { 'marketing_attribution' => { 'last_touch' => { 'gclid' => 'g-click' } } })

    described_class.new(account: account, event_name: 'cloud_signup').perform

    expect(a_request(:post, api_url)).not_to have_been_made
  end

  it 'sends nothing while the X config is empty' do
    InstallationConfig.find_by(name: described_class::CONFIG_KEY).update!(value: nil)

    described_class.new(account: account, event_name: 'cloud_signup').perform

    expect(a_request(:post, api_url)).not_to have_been_made
  end

  it 'raises so the job retries when X rejects the upload' do
    stub_request(:post, api_url).to_return(status: 503, body: 'unavailable')

    expect do
      described_class.new(account: account, event_name: 'cloud_signup').perform
    end.to raise_error(RuntimeError, /X conversion upload failed/)
  end

  it 'runs from the existing marketing conversion job' do
    google_service = instance_double(Internal::Accounts::MarketingConversionTrackingService, perform: nil)
    allow(Internal::Accounts::MarketingConversionTrackingService).to receive(:new).and_return(google_service)

    Internal::Accounts::MarketingConversionTrackingJob.perform_now(account.id, 'cloud_signup', occurred_at)

    expect(sent_conversion['event_id']).to eq('tw-o1abc-signup')
  end
end
