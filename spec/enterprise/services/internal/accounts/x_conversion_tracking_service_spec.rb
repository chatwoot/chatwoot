# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Internal::Accounts::XConversionTrackingService do
  let(:account) { create(:account, created_at: Time.zone.parse('2026-11-05T10:05:00Z')) }
  let(:api_url) { 'https://ads-api.x.com/12/measurement/conversions/o1abc' }
  let(:config) do
    {
      'pixel_id' => 'o1abc',
      'consumer_key' => 'consumer-key', 'consumer_secret' => 'consumer-secret',
      'access_token' => 'access-token', 'access_token_secret' => 'access-token-secret',
      'events' => {
        'cloud_signup' => { 'event_id' => 'tw-o1abc-signup' },
        'cloud_first_payment' => { 'event_id' => 'tw-o1abc-payment' }
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

  it 'sends the signup with the last-touch twclid, a stable conversion id and an OAuth 1.0a signature' do
    described_class.new(account: account, event_name: 'cloud_signup').perform

    expect(
      a_request(:post, api_url).with do |request|
        request.headers['Authorization'].start_with?('OAuth ') &&
          request.headers['Authorization'].include?('oauth_consumer_key="consumer-key"') &&
          JSON.parse(request.body) == {
            'conversions' => [{
              'conversion_time' => '2026-11-05T10:05:00.000Z',
              'event_id' => 'tw-o1abc-signup',
              'identifiers' => [{ 'twclid' => 'x-click-last' }],
              'conversion_id' => "cloud_signup-account-#{account.id}"
            }]
          }
      end
    ).to have_been_made.once
  end

  it 'sends the first payment at its paid time with its value' do
    account.update!(internal_attributes: account.internal_attributes.merge(
      'first_payment' => { 'paid_at' => '2026-11-12T08:30:00Z', 'amount_paid' => 1900, 'currency' => 'usd' }
    ))

    described_class.new(account: account, event_name: 'cloud_first_payment').perform

    expect(
      a_request(:post, api_url).with do |request|
        JSON.parse(request.body)['conversions'].first == {
          'conversion_time' => '2026-11-12T08:30:00.000Z',
          'event_id' => 'tw-o1abc-payment',
          'identifiers' => [{ 'twclid' => 'x-click-last' }],
          'conversion_id' => "cloud_first_payment-account-#{account.id}",
          'value' => 19.0,
          'price_currency' => 'USD'
        }
      end
    ).to have_been_made.once
  end

  it 'falls back to the first-touch twclid' do
    marketing_attribution['last_touch'] = { 'source' => 'google', 'gclid' => 'g-click' }
    account.update!(internal_attributes: { 'marketing_attribution' => marketing_attribution })

    described_class.new(account: account, event_name: 'cloud_signup').perform

    expect(a_request(:post, api_url).with { |request| request.body.include?('x-click-first') }).to have_been_made.once
  end

  it 'sends nothing without a twclid' do
    account.update!(internal_attributes: { 'marketing_attribution' => { 'last_touch' => { 'source' => 'x', 'utm_source' => 'x' } } })

    described_class.new(account: account, event_name: 'cloud_signup').perform

    expect(a_request(:post, api_url)).not_to have_been_made
  end

  it 'sends nothing while the X config is empty' do
    InstallationConfig.find_by(name: described_class::CONFIG_KEY).update!(value: nil)

    described_class.new(account: account, event_name: 'cloud_signup').perform

    expect(a_request(:post, api_url)).not_to have_been_made
  end

  it 'sends nothing outside Chatwoot Cloud' do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)

    described_class.new(account: account, event_name: 'cloud_signup').perform

    expect(a_request(:post, api_url)).not_to have_been_made
  end

  it 'raises so the job retries when X rejects the upload' do
    stub_request(:post, api_url).to_return(status: 503, body: 'unavailable')

    expect do
      described_class.new(account: account, event_name: 'cloud_signup').perform
    end.to raise_error(RuntimeError, /X conversion upload failed/)
  end
end
