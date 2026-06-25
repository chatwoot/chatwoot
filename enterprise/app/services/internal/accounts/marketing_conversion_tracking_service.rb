# frozen_string_literal: true

require 'base64'
require 'openssl'

class Internal::Accounts::MarketingConversionTrackingService
  CONFIG_KEY = 'MARKETING_CONVERSION_TRACKING_CONFIG'
  TOKEN_URL = 'https://oauth2.googleapis.com/token'
  TOKEN_SCOPE = 'https://www.googleapis.com/auth/datamanager'
  API_URL = 'https://datamanager.googleapis.com/v1/events:ingest'
  CLICK_ID_FIELDS = %w[gclid gbraid wbraid].freeze

  pattr_initialize [:account!, :event_name!, :occurred_at, :conversion_value, :currency_code]

  def perform
    return unless ChatwootApp.chatwoot_cloud?
    return if click_attributes.blank?

    upload_conversion!
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: account).capture_exception
  end

  private

  def upload_conversion!
    response = HTTParty.post(
      API_URL,
      headers: api_headers,
      body: {
        destinations: [destination_payload],
        events: [conversion_payload]
      }.to_json
    )

    raise "Marketing conversion upload failed: #{response.body}" unless response.success?
  end

  def destination_payload
    {
      operatingAccount: {
        accountType: 'GOOGLE_ADS',
        accountId: customer_id
      },
      loginAccount: {
        accountType: 'GOOGLE_ADS',
        accountId: login_customer_id
      },
      productDestinationId: conversion_action_id
    }
  end

  def conversion_payload
    payload = {
      transactionId: order_id,
      eventTimestamp: conversion_time,
      eventSource: 'WEB',
      adIdentifiers: click_attributes
    }

    payload[:conversionValue] = conversion_amount if conversion_amount.present?
    payload[:currency] = conversion_currency if conversion_amount.present?
    payload
  end

  def click_attributes
    @click_attributes ||= CLICK_ID_FIELDS.filter_map do |field|
      value = attribution[field]
      [field.to_sym, value] if value.present?
    end.to_h
  end

  def attribution
    @attribution ||= marketing_attribution['last_touch'].presence || marketing_attribution['first_touch'].presence || {}
  end

  def marketing_attribution
    @marketing_attribution ||= account.internal_attributes['marketing_attribution'] || {}
  end

  def access_token
    @access_token ||= begin
      response = HTTParty.post(
        TOKEN_URL,
        body: {
          grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          assertion: service_account_assertion
        }
      )

      raise "Marketing conversion token request failed: #{response.body}" unless response.success?

      response.parsed_response['access_token']
    end
  end

  def service_account_assertion
    now = Time.current.to_i
    header = { alg: 'RS256', typ: 'JWT' }
    claim_set = {
      iss: service_account_credentials['client_email'],
      scope: TOKEN_SCOPE,
      aud: TOKEN_URL,
      exp: now + 1.hour.to_i,
      iat: now
    }

    signing_input = [header, claim_set].map { |part| base64_url_encode(part.to_json) }.join('.')
    signature = OpenSSL::PKey::RSA.new(service_account_credentials['private_key']).sign(OpenSSL::Digest.new('SHA256'), signing_input)
    "#{signing_input}.#{base64_url_encode(signature)}"
  end

  def api_headers
    {
      'Authorization' => "Bearer #{access_token}",
      'Content-Type' => 'application/json'
    }
  end

  def config
    @config ||= begin
      value = InstallationConfig.find_by!(name: CONFIG_KEY).value
      value.is_a?(String) ? JSON.parse(value) : value
    end
  end

  def event_config
    @event_config ||= config['events'][event_name]
  end

  def customer_id
    config['customer_id'].delete('-')
  end

  def login_customer_id
    config['login_customer_id'].delete('-')
  end

  def conversion_action_id
    event_config['conversion_action_id']
  end

  def conversion_time
    time = occurred_at.present? ? Time.zone.parse(occurred_at.to_s) : Time.current
    time.iso8601
  end

  def conversion_amount
    @conversion_amount ||= conversion_value.presence&.to_f
  end

  def conversion_currency
    currency_code.presence || 'USD'
  end

  def service_account_credentials
    @service_account_credentials ||= config['service_account_credentials']
  end

  def base64_url_encode(value)
    Base64.urlsafe_encode64(value, padding: false)
  end

  def order_id
    "#{event_name}-account-#{account.id}"
  end
end
