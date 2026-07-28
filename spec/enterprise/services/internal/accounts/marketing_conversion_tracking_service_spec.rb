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
end
