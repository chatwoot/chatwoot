# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Internal::Accounts::MarketingConversionTrackingService do
  let(:account) { create(:account) }
  let(:event_name) { 'cloud_signup' }
  let(:occurred_at) { '2026-06-23T10:30:00Z' }
  let(:private_key) { OpenSSL::PKey::RSA.new(2048).to_pem }

  before do
    InstallationConfig.where(name: described_class::CONFIG_KEY).delete_all
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
  end

  it 'does nothing outside Chatwoot Cloud' do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)
    create_config

    expect(HTTParty).not_to receive(:post)

    described_class.new(account: account, event_name: event_name, occurred_at: occurred_at).perform
  end

  it 'uploads the last-touch click conversion', :aggregate_failures do
    create_config
    account.update!(internal_attributes: attribution_attributes('last-click'))
    token_response = response_double('access_token' => 'access-token')
    upload_response = response_double('requestId' => 'request-123')
    upload_request = nil

    allow(HTTParty).to receive(:post) do |url, options|
      if url == described_class::TOKEN_URL
        token_response
      else
        upload_request = [url, options]
        upload_response
      end
    end

    described_class.new(account: account, event_name: event_name, occurred_at: occurred_at).perform

    url, options = upload_request
    body = JSON.parse(options[:body])

    expect(url).to eq('https://datamanager.googleapis.com/v1/events:ingest')
    expect(HTTParty).to have_received(:post).with(
      described_class::TOKEN_URL,
      body: hash_including(
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: be_present
      )
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
      'adIdentifiers' => { 'gclid' => 'last-click' }
    )
    expect(body['events'].first.keys).not_to include('conversionValue', 'currency')

    expect(account.reload.internal_attributes).not_to have_key('marketing_conversions')
  end

  it 'falls back to first-touch attribution when last-touch attribution is absent' do
    create_config
    account.update!(
      internal_attributes: {
        'marketing_attribution' => {
          'first_touch' => { 'gclid' => 'first-click' }
        }
      }
    )
    token_response = response_double('access_token' => 'access-token')
    upload_response = response_double('requestId' => 'request-123')
    upload_body = nil

    allow(HTTParty).to receive(:post) do |url, options|
      if url == described_class::TOKEN_URL
        token_response
      else
        upload_body = JSON.parse(options[:body])
        upload_response
      end
    end

    described_class.new(account: account, event_name: event_name, occurred_at: occurred_at).perform

    expect(upload_body['events'].first['adIdentifiers']['gclid']).to eq('first-click')
  end

  it 'uploads conversion value and currency when provided' do
    create_config
    account.update!(internal_attributes: attribution_attributes('last-click'))
    token_response = response_double('access_token' => 'access-token')
    upload_response = response_double('requestId' => 'request-123')
    upload_body = nil

    allow(HTTParty).to receive(:post) do |url, options|
      if url == described_class::TOKEN_URL
        token_response
      else
        upload_body = JSON.parse(options[:body])
        upload_response
      end
    end

    described_class.new(
      account: account,
      event_name: event_name,
      occurred_at: occurred_at,
      conversion_value: 199,
      currency_code: 'USD'
    ).perform

    expect(upload_body['events'].first).to include(
      'conversionValue' => 199.0,
      'currency' => 'USD'
    )
  end

  it 'defaults currency when conversion value is present without currency' do
    create_config
    account.update!(internal_attributes: attribution_attributes('last-click'))
    token_response = response_double('access_token' => 'access-token')
    upload_response = response_double('requestId' => 'request-123')
    upload_body = nil

    allow(HTTParty).to receive(:post) do |url, options|
      if url == described_class::TOKEN_URL
        token_response
      else
        upload_body = JSON.parse(options[:body])
        upload_response
      end
    end

    described_class.new(
      account: account,
      event_name: event_name,
      occurred_at: occurred_at,
      conversion_value: 199
    ).perform

    expect(upload_body['events'].first).to include(
      'conversionValue' => 199.0,
      'currency' => 'USD'
    )
  end

  def create_config(overrides = {})
    create(
      :installation_config,
      name: described_class::CONFIG_KEY,
      value: default_config.deep_merge(overrides)
    )
  end

  def default_config
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

  def attribution_attributes(gclid)
    {
      'marketing_attribution' => {
        'first_touch' => { 'gclid' => 'first-click' },
        'last_touch' => { 'gclid' => gclid }
      }
    }
  end

  def response_double(parsed_response)
    instance_double(HTTParty::Response, success?: true, parsed_response: parsed_response, body: parsed_response.to_json)
  end
end
