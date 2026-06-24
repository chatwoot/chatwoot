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
    return unless configured?
    return if already_sent?
    return if click_attributes.blank?
    return if conversion_action_id.blank?

    upload_conversion!
    mark_sent!
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: account).capture_exception
  end

  private

  def already_sent?
    conversions_state.dig(event_name, 'sent_at').present?
  end

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

    parsed_response = response.parsed_response || {}
    raise "Marketing conversion upload response missing request ID: #{response.body}" if parsed_response['requestId'].blank?
  end

  def configured?
    enabled_config? && event_config.present? && required_config_present?
  end

  def destination_payload
    payload = {
      operatingAccount: {
        accountType: 'GOOGLE_ADS',
        accountId: customer_id
      },
      productDestinationId: conversion_action_id
    }

    if login_customer_id.present?
      payload[:loginAccount] = {
        accountType: 'GOOGLE_ADS',
        accountId: login_customer_id
      }
    end

    payload
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
    @marketing_attribution ||= internal_attributes_service.get('marketing_attribution') || {}
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
      value = InstallationConfig.find_by(name: CONFIG_KEY)&.value || {}
      value.is_a?(String) ? JSON.parse(value) : value
    rescue JSON::ParserError
      {}
    end
  end

  def required_config_present?
    config['customer_id'].present? &&
      service_account_credentials['client_email'].present? &&
      service_account_credentials['private_key'].present?
  end

  def enabled_config?
    ActiveModel::Type::Boolean.new.cast(config['enabled'])
  end

  def event_config
    @event_config ||= config.dig('events', event_name) || {}
  end

  def customer_id
    config['customer_id'].to_s.delete('-')
  end

  def login_customer_id
    config['login_customer_id'].to_s.delete('-')
  end

  def conversion_action_id
    event_config['conversion_action_id'].presence
  end

  def conversion_time
    time = occurred_at.present? ? Time.zone.parse(occurred_at.to_s) : Time.current
    time.iso8601
  end

  def conversion_amount
    @conversion_amount ||= (conversion_value.presence || event_config['value'].presence)&.to_f
  end

  def conversion_currency
    currency_code.presence || event_config['currency_code'].presence || 'USD'
  end

  def service_account_credentials
    @service_account_credentials ||= config['service_account_credentials'] || {}
  end

  def base64_url_encode(value)
    Base64.urlsafe_encode64(value, padding: false)
  end

  def order_id
    "#{event_name}-account-#{account.id}"
  end

  def mark_sent!
    updated_state = conversions_state.merge(
      event_name => {
        'sent_at' => Time.current.iso8601,
        'conversion_action_id' => conversion_action_id,
        'click_id_fields' => click_attributes.keys.map(&:to_s),
        'order_id' => order_id
      }
    )
    internal_attributes_service.set('marketing_conversions', updated_state)
  end

  def conversions_state
    @conversions_state ||= internal_attributes_service.get('marketing_conversions') || {}
  end

  def internal_attributes_service
    @internal_attributes_service ||= Internal::Accounts::InternalAttributesService.new(account)
  end
end
