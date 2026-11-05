# frozen_string_literal: true

# Sends a Chatwoot Cloud conversion to the X Conversion API for accounts whose website
# attribution carries an X click id (twclid). The twclid is the only identifier sent: no
# email, phone or IP. Nothing is sent while X_CONVERSION_TRACKING_CONFIG is empty.
class Internal::Accounts::XConversionTrackingService
  CONFIG_KEY = 'X_CONVERSION_TRACKING_CONFIG'
  # Expected config shape:
  # {
  #   "pixel_id": "o1abc",
  #   "consumer_key": "...", "consumer_secret": "...",
  #   "access_token": "...", "access_token_secret": "...",
  #   "events": {
  #     "cloud_signup": { "event_id": "tw-o1abc-o1def" },
  #     "cloud_first_payment": { "event_id": "tw-o1abc-o1ghi" }
  #   }
  # }
  API_SITE = 'https://ads-api.x.com'
  API_VERSION = '12'

  pattr_initialize [:account!, :event_name!]

  def perform
    return unless ChatwootApp.chatwoot_cloud?
    return if config.blank? || twclid.blank?

    response = access_token.post(
      "/#{API_VERSION}/measurement/conversions/#{config['pixel_id']}",
      { conversions: [conversion] }.to_json,
      'Content-Type' => 'application/json'
    )

    raise "X conversion upload failed: #{response.body}" unless response.is_a?(Net::HTTPSuccess)
  end

  private

  def conversion
    payload = {
      conversion_time: conversion_time.utc.iso8601(3),
      event_id: config['events'][event_name]['event_id'],
      identifiers: [{ twclid: twclid }],
      conversion_id: "#{event_name}-account-#{account.id}"
    }
    return payload unless event_name == 'cloud_first_payment'

    payload.merge(value: first_payment['amount_paid'] / 100.0, price_currency: first_payment['currency'].upcase)
  end

  def conversion_time
    return Time.zone.parse(first_payment['paid_at']) if event_name == 'cloud_first_payment'

    account.created_at
  end

  def first_payment
    account.internal_attributes.fetch('first_payment')
  end

  # The click nearest the conversion: last touch first, as the Google upload does.
  def twclid
    marketing_attribution = account.internal_attributes['marketing_attribution'] || {}
    [marketing_attribution['last_touch'], marketing_attribution['first_touch']].filter_map { |touch| touch&.dig('twclid').presence }.first
  end

  def access_token
    consumer = OAuth::Consumer.new(config['consumer_key'], config['consumer_secret'], site: API_SITE)
    OAuth::AccessToken.new(consumer, config['access_token'], config['access_token_secret'])
  end

  def config
    @config ||= begin
      value = InstallationConfig.find_by(name: CONFIG_KEY)&.value.presence
      value.is_a?(String) ? JSON.parse(value) : value
    end
  end
end
