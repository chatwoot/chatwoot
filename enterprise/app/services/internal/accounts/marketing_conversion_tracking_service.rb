# frozen_string_literal: true

require 'googleauth'

class Internal::Accounts::MarketingConversionTrackingService
  CONFIG_KEY = 'MARKETING_CONVERSION_TRACKING_CONFIG'
  # Expected config shape:
  # {
  #   "customer_id": "123-456-7890",
  #   "login_customer_id": "123-456-7890",
  #   "service_account_credentials": { ... },
  #   "events": {
  #     "cloud_signup": { "conversion_action_id": "123456789" },
  #     "cloud_plan_activation": { "conversion_action_id": "987654321" }
  #   },
  #   "x": {
  #     "pixel_id": "o1abc",
  #     "pixel_token": "...",
  #     "events": {
  #       "cloud_signup": { "event_id": "tw-o1abc-o1def" },
  #       "cloud_plan_activation": { "event_id": "tw-o1abc-o1ghi" }
  #     }
  #   }
  # }
  TOKEN_SCOPES = ['https://www.googleapis.com/auth/datamanager'].freeze
  API_URL = 'https://datamanager.googleapis.com/v1/events:ingest'
  CLICK_ID_FIELDS = %w[gclid gbraid wbraid].freeze
  X_API_URL = 'https://ads-api.x.com/12/measurement/conversions'

  pattr_initialize [:account!, :event_name!, :occurred_at, :conversion_value, :currency_code]

  def perform
    return unless ChatwootApp.chatwoot_cloud?

    upload_google_conversion if click_attributes.present?
    upload_x_conversion if twclid.present? && config['x'].present?
  end

  private

  def upload_google_conversion
    response = HTTParty.post(
      API_URL,
      headers: {
        'Authorization' => "Bearer #{access_token}",
        'Content-Type' => 'application/json'
      },
      body: {
        destinations: [destination_payload],
        events: [conversion_payload]
      }.to_json
    )

    raise "Marketing conversion upload failed: #{response.body}" unless response.success?
  end

  def upload_x_conversion
    response = HTTParty.post(
      "#{X_API_URL}/#{config['x']['pixel_id']}",
      headers: {
        'X-Pixel-Token' => config['x']['pixel_token'],
        'Content-Type' => 'application/json'
      },
      body: { conversions: [x_conversion_payload] }.to_json
    )

    raise "X conversion upload failed: #{response.body}" unless response.success?
  end

  def destination_payload
    {
      operatingAccount: {
        accountType: 'GOOGLE_ADS',
        accountId: config['customer_id'].delete('-')
      },
      loginAccount: {
        accountType: 'GOOGLE_ADS',
        accountId: config['login_customer_id'].delete('-')
      },
      productDestinationId: config['events'][event_name]['conversion_action_id']
    }
  end

  def conversion_payload
    payload = {
      transactionId: "#{event_name}-account-#{account.id}",
      eventTimestamp: event_timestamp.iso8601,
      eventSource: 'WEB',
      adIdentifiers: click_attributes
    }

    if conversion_value.present?
      payload[:conversionValue] = conversion_value.to_f
      payload[:currency] = currency_code.presence || 'USD'
    end

    payload
  end

  def x_conversion_payload
    payload = {
      conversion_id: "#{event_name}-account-#{account.id}",
      conversion_time: event_timestamp.utc.iso8601(3),
      event_id: config['x']['events'][event_name]['event_id'],
      identifiers: [{ twclid: twclid }]
    }

    if conversion_value.present?
      payload[:value] = format('%.2f', conversion_value.to_f)
      payload[:price_currency] = currency_code.presence || 'USD'
    end

    payload
  end

  def click_attributes
    @click_attributes ||= CLICK_ID_FIELDS.filter_map do |field|
      value = attribution[field]
      [field.to_sym, value] if value.present?
    end.to_h
  end

  def event_timestamp
    occurred_at || Time.current
  end

  def attribution
    touches.find do |touch|
      CLICK_ID_FIELDS.any? { |field| touch[field].present? }
    end || {}
  end

  def twclid
    touches.filter_map { |touch| touch['twclid'].presence }.first
  end

  def touches
    marketing_attribution = account.internal_attributes['marketing_attribution'] || {}
    [marketing_attribution['last_touch'], marketing_attribution['first_touch']].compact_blank
  end

  def access_token
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(config['service_account_credentials'].to_json),
      scope: TOKEN_SCOPES
    )
    authorizer.fetch_access_token!['access_token']
  end

  def config
    @config ||= JSON.parse(InstallationConfig.find_by!(name: CONFIG_KEY).value)
  end
end
