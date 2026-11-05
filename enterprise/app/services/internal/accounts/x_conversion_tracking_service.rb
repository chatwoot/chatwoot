# frozen_string_literal: true

# The X counterpart of MarketingConversionTrackingService: the same Cloud signup and plan
# activation events, sent to the X Conversion API for accounts whose attribution carries an
# X click id. Only the twclid is sent, and nothing at all while the config is empty.
class Internal::Accounts::XConversionTrackingService
  CONFIG_KEY = 'X_CONVERSION_TRACKING_CONFIG'
  # Expected config shape:
  # {
  #   "pixel_id": "o1abc",
  #   "consumer_key": "...", "consumer_secret": "...", "access_token": "...", "access_token_secret": "...",
  #   "events": {
  #     "cloud_signup": { "event_id": "tw-o1abc-o1def" },
  #     "cloud_plan_activation": { "event_id": "tw-o1abc-o1ghi" }
  #   }
  # }
  API_SITE = 'https://ads-api.x.com'

  pattr_initialize [:account!, :event_name!, :occurred_at, :conversion_value, :currency_code]

  def perform
    return unless ChatwootApp.chatwoot_cloud?
    return if config.blank? || twclid.blank?

    response = access_token.post("/12/measurement/conversions/#{config['pixel_id']}", { conversions: [conversion_payload] }.to_json,
                                 'Content-Type' => 'application/json')

    raise "X conversion upload failed: #{response.body}" unless response.is_a?(Net::HTTPSuccess)
  end

  private

  def conversion_payload
    payload = {
      conversion_id: "#{event_name}-account-#{account.id}",
      conversion_time: (occurred_at || Time.current).utc.iso8601(3),
      event_id: config['events'][event_name]['event_id'],
      identifiers: [{ twclid: twclid }]
    }

    if conversion_value.present?
      payload[:value] = conversion_value.to_f
      payload[:price_currency] = currency_code.presence || 'USD'
    end

    payload
  end

  def twclid
    marketing_attribution = account.internal_attributes['marketing_attribution'] || {}
    [marketing_attribution['last_touch'], marketing_attribution['first_touch']].filter_map { |touch| touch&.dig('twclid').presence }.first
  end

  def access_token
    consumer = OAuth::Consumer.new(config['consumer_key'], config['consumer_secret'], site: API_SITE)
    OAuth::AccessToken.new(consumer, config['access_token'], config['access_token_secret'])
  end

  def config
    @config ||= InstallationConfig.find_by(name: CONFIG_KEY)&.value.presence&.then { |value| JSON.parse(value) }
  end
end
