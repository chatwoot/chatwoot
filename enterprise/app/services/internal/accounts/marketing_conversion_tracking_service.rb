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
  #   }
  # }
  TOKEN_SCOPES = ['https://www.googleapis.com/auth/datamanager'].freeze
  API_URL = 'https://datamanager.googleapis.com/v1/events:ingest'
  CLICK_ID_FIELDS = %w[gclid gbraid wbraid].freeze

  pattr_initialize [:account!, :event_name!, :occurred_at, :conversion_value, :currency_code]

  def perform
    return unless ChatwootApp.chatwoot_cloud?
    return if click_attributes.blank?

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

  private

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
    marketing_attribution = account.internal_attributes['marketing_attribution'] || {}
    [marketing_attribution['last_touch'], marketing_attribution['first_touch']].find do |touch|
      touch.present? && CLICK_ID_FIELDS.any? { |field| touch[field].present? }
    end || {}
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
