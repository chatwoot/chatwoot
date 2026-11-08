# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Internal::Accounts::MarketingConversionTrackingService do
  let(:account) { create(:account) }
  let(:event_name) { 'cloud_signup' }
  let(:occurred_at) { Time.zone.parse('2026-06-23T10:30:00Z') }
  let(:private_key) { OpenSSL::PKey::RSA.new(2048).to_pem }
  let(:credentials) do
    instance_double(Google::Auth::ServiceAccountCredentials, fetch_access_token!: { 'access_token' => 'access-token' })
  end
  let(:config) do
    {
      'customer_id' => '852-320-2898',
      'login_customer_id' => '742-202-9198',
      'service_account_credentials' => {
        'client_email' => 'marketing-conversions@chatwoot-production.iam.gserviceaccount.com',
        'private_key' => private_key
      },
      'events' => {
        'cloud_signup' => {
          'conversion_action_id' => '123456789'
        }
      }
    }
  end
  let(:marketing_attribution) do
    {
      'first_touch' => { 'gclid' => 'first-click' },
      'last_touch' => { 'gclid' => 'last-click' }
    }
  end

  before do
    create(:installation_config, name: described_class::CONFIG_KEY, value: config.to_json)
    account.update!(internal_attributes: { 'marketing_attribution' => marketing_attribution })

    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
    allow(Google::Auth::ServiceAccountCredentials).to receive(:make_creds).and_return(credentials)
  end

  it 'does nothing outside Chatwoot Cloud' do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)

    expect(HTTParty).not_to receive(:post)

    described_class.new(account: account, event_name: event_name, occurred_at: occurred_at).perform
  end

  it 'uploads the last-touch click conversion', :aggregate_failures do
    upload_request = nil

    allow(HTTParty).to receive(:post) do |url, options|
      upload_request = [url, options]
      instance_double(HTTParty::Response, success?: true, body: '{}')
    end

    described_class.new(
      account: account,
      event_name: event_name,
      occurred_at: occurred_at,
      conversion_value: 199,
      currency_code: 'USD'
    ).perform

    url, options = upload_request
    body = JSON.parse(options[:body])

    expect(url).to eq('https://datamanager.googleapis.com/v1/events:ingest')
    expect(Google::Auth::ServiceAccountCredentials).to have_received(:make_creds).with(
      json_key_io: kind_of(StringIO),
      scope: ['https://www.googleapis.com/auth/datamanager']
    )
    expect(options[:headers]).to include(
      'Authorization' => 'Bearer access-token'
    )
    expect(body['destinations'].first).to include(
      'operatingAccount' => {
        'accountType' => 'GOOGLE_ADS',
        'accountId' => '8523202898'
      },
      'loginAccount' => {
        'accountType' => 'GOOGLE_ADS',
        'accountId' => '7422029198'
      },
      'productDestinationId' => '123456789'
    )
    expect(body['events'].first).to include(
      'transactionId' => "cloud_signup-account-#{account.id}",
      'eventTimestamp' => '2026-06-23T10:30:00Z',
      'eventSource' => 'WEB',
      'adIdentifiers' => { 'gclid' => 'last-click' },
      'conversionValue' => 199.0,
      'currency' => 'USD'
    )
  end

  it 'falls back to first-touch attribution when last-touch attribution has no click id' do
    account.update!(
      internal_attributes: {
        'marketing_attribution' => {
          'last_touch' => { 'source' => 'github' },
          'first_touch' => { 'gclid' => 'first-click' }
        }
      }
    )
    upload_body = nil

    allow(HTTParty).to receive(:post) do |_url, options|
      upload_body = JSON.parse(options[:body])
      instance_double(HTTParty::Response, success?: true, body: '{}')
    end

    described_class.new(account: account, event_name: event_name, occurred_at: occurred_at).perform

    expect(upload_body['events'].first['adIdentifiers']['gclid']).to eq('first-click')
  end

  context 'with an X click id' do
    let(:x_api_url) { 'https://ads-api.x.com/12/measurement/conversions/o1abc' }
    let(:x_config) do
      {
        'pixel_id' => 'o1abc',
        'pixel_token' => 'pixel-token',
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
      InstallationConfig.find_by(name: described_class::CONFIG_KEY).update!(value: config.merge('x' => x_config).to_json)
      stub_request(:post, x_api_url).to_return(status: 200, body: { data: {} }.to_json)
      allow(HTTParty).to receive(:post).and_call_original
      allow(HTTParty).to receive(:post).with(described_class::API_URL, anything)
    end

    def sent_x_conversion
      body = nil
      expect(a_request(:post, x_api_url).with { |request| body = JSON.parse(request.body) }).to have_been_made.once
      body['conversions'].first
    end

    it 'sends the signup to X with the last-touch twclid, a stable conversion id and the pixel token' do
      described_class.new(account: account, event_name: event_name, occurred_at: occurred_at).perform

      expect(a_request(:post, x_api_url).with(headers: { 'X-Pixel-Token' => 'pixel-token' })).to have_been_made.once
      expect(sent_x_conversion).to eq(
        'conversion_id' => "cloud_signup-account-#{account.id}",
        'conversion_time' => '2026-06-23T10:30:00.000Z',
        'event_id' => 'tw-o1abc-signup',
        'identifiers' => [{ 'twclid' => 'x-click-last' }]
      )
      expect(HTTParty).not_to have_received(:post).with(described_class::API_URL, anything)
    end

    it 'sends the plan activation to X with its value' do
      described_class.new(account: account, event_name: 'cloud_plan_activation', occurred_at: occurred_at,
                          conversion_value: 19.0, currency_code: 'USD').perform

      expect(sent_x_conversion).to include('event_id' => 'tw-o1abc-activation', 'value' => '19.00', 'price_currency' => 'USD')
    end

    it 'falls back to the first-touch twclid and still uploads the Google click' do
      marketing_attribution['last_touch'] = { 'source' => 'google', 'gclid' => 'g-click' }
      account.update!(internal_attributes: { 'marketing_attribution' => marketing_attribution })
      allow(HTTParty).to receive(:post).with(described_class::API_URL, anything)
                                       .and_return(instance_double(HTTParty::Response, success?: true, body: '{}'))

      described_class.new(account: account, event_name: event_name, occurred_at: occurred_at).perform

      expect(sent_x_conversion['identifiers']).to eq([{ 'twclid' => 'x-click-first' }])
      expect(HTTParty).to have_received(:post).with(described_class::API_URL, anything).once
    end

    it 'sends nothing to X until the x config is set' do
      InstallationConfig.find_by(name: described_class::CONFIG_KEY).update!(value: config.to_json)

      described_class.new(account: account, event_name: event_name, occurred_at: occurred_at).perform

      expect(a_request(:post, x_api_url)).not_to have_been_made
    end
  end
end
