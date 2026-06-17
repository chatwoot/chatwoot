# frozen_string_literal: true

class Internal::Accounts::MarketingAttributionService
  FIRST_TOUCH_COOKIE = 'cw_first_touch_attribution'
  LAST_TOUCH_COOKIE = 'cw_last_touch_attribution'
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

  pattr_initialize [:account!, :cookies!]

  def perform
    return unless ChatwootApp.chatwoot_cloud?

    first_touch = attribution_cookie(FIRST_TOUCH_COOKIE)
    last_touch = attribution_cookie(LAST_TOUCH_COOKIE)
    return unless first_touch || last_touch

    existing_attribution = account.internal_attributes['marketing_attribution'] || {}
    account.update!(
      internal_attributes: account.internal_attributes.merge(
        'marketing_attribution' => {
          'first_touch' => first_touch || existing_attribution['first_touch'],
          'last_touch' => last_touch || existing_attribution['last_touch'],
          'captured_from' => 'cookie',
          'stored_at' => Time.current.iso8601
        }.compact
      )
    )
  end

  private

  def attribution_cookie(cookie_name)
    return if cookies[cookie_name].blank?

    parse_cookie(cookies[cookie_name].to_s)
  end

  def parse_cookie(cookie_value)
    validate_payload(JSON.parse(cookie_value))
  rescue JSON::ParserError, ArgumentError
    parse_percent_encoded_cookie(cookie_value)
  end

  def parse_percent_encoded_cookie(cookie_value)
    validate_payload(JSON.parse(percent_decode(cookie_value)))
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

  def percent_decode(value)
    value.gsub(/%[0-9A-Fa-f]{2}/) do |encoded_byte|
      [encoded_byte[1..].to_i(16)].pack('C')
    end.force_encoding(Encoding::UTF_8)
  end
end
