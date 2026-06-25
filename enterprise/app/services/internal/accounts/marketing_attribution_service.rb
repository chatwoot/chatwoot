# frozen_string_literal: true

require 'base64'

class Internal::Accounts::MarketingAttributionService
  FIRST_TOUCH_COOKIE = 'cw_first_touch_attribution'
  LAST_TOUCH_COOKIE = 'cw_last_touch_attribution'
  PLAN_ACTIVATION_TRACKED_AT = 'cloud_plan_activation_tracked_at'
  CLOUD_PLANS_CONFIG = 'CHATWOOT_CLOUD_PLANS'
  FIELD_MAX_LENGTH = 500
  ALLOWED_FIELDS = %w[
    utm_source
    utm_medium
    utm_campaign
    utm_term
    utm_content
    utm_id
    gclid
    gbraid
    wbraid
    dclid
    fbclid
    msclkid
    ttclid
    li_fat_id
    twclid
    rdt_cid
    referrer
    referrer_path
    landing_page
    source
    source_type
    captured_at
  ].freeze

  pattr_initialize [:account!, { cookies: {} }]

  def perform
    return unless ChatwootApp.chatwoot_cloud?

    first_touch = attribution_cookie(FIRST_TOUCH_COOKIE)
    last_touch = attribution_cookie(LAST_TOUCH_COOKIE)
    return unless first_touch || last_touch

    existing_attribution = internal_attributes_service.get('marketing_attribution') || {}
    internal_attributes_service.set(
      'marketing_attribution',
      {
        'first_touch' => first_touch || existing_attribution['first_touch'],
        'last_touch' => last_touch || existing_attribution['last_touch'],
        'captured_from' => 'cookie',
        'stored_at' => Time.current.iso8601
      }.compact
    )
    enqueue_signup_conversion
  end

  def track_plan_activation(previous_plan_name:, current_plan_name:, activated_at:, conversion_value:, currency_code:)
    return unless ChatwootApp.chatwoot_cloud?

    marketing_attribution = internal_attributes_service.get('marketing_attribution')

    return unless track_plan_activation?(previous_plan_name, current_plan_name, activated_at, marketing_attribution)

    Internal::Accounts::MarketingConversionTrackingJob.perform_later(
      account.id,
      'cloud_plan_activation',
      activated_at,
      conversion_value,
      currency_code
    )
    internal_attributes_service.set(
      'marketing_attribution',
      marketing_attribution.merge(PLAN_ACTIVATION_TRACKED_AT => Time.current.iso8601)
    )
  end

  private

  def attribution_cookie(cookie_name)
    return if cookies[cookie_name].blank?

    parse_cookie(cookies[cookie_name].to_s)
  end

  def parse_cookie(cookie_value)
    validate_payload(JSON.parse(Base64.urlsafe_decode64(cookie_value)))
  rescue JSON::ParserError, ArgumentError
    nil
  end

  def validate_payload(payload)
    return unless payload.is_a?(Hash)

    payload.slice(*ALLOWED_FIELDS).filter_map do |key, value|
      next if value.blank? || value.is_a?(Array) || value.is_a?(Hash)

      [key, value.to_s.first(FIELD_MAX_LENGTH)]
    end.to_h.presence
  end

  def internal_attributes_service
    @internal_attributes_service ||= Internal::Accounts::InternalAttributesService.new(account)
  end

  def enqueue_signup_conversion
    Internal::Accounts::MarketingConversionTrackingJob.perform_later(account.id, 'cloud_signup', account.created_at)
  end

  def track_plan_activation?(previous_plan_name, current_plan_name, activated_at, marketing_attribution)
    default_plan = InstallationConfig.find_by(name: CLOUD_PLANS_CONFIG).value.first['name']

    previous_plan_name == default_plan &&
      current_plan_name != default_plan &&
      marketing_attribution.present? &&
      marketing_attribution[PLAN_ACTIVATION_TRACKED_AT].blank? &&
      activated_at <= account.created_at + 30.days
  end
end
