# frozen_string_literal: true

# Normalises one raw CSV row (a HashWithIndifferentAccess of header->value)
# into the logical fields the importer cares about. Pure, no DB access, so it
# is trivially unit-testable and decoupled from ActiveRecord.
module CsvImport
  class Row
    # Fields we copy verbatim into contact custom_attributes (everything that
    # isn't a first-class contact/company column).
    CONTACT_CUSTOM_ATTRS = %w[
      place_id query category categories maps_url street postal_code state
      latitude longitude plus_code timezone phones whatsapp instagram facebook
      tiktok linkedin youtube twitter rating review_count status description
      business_summary open_hours operating_hours_text price_range about
      thumbnail staff_count products cuisine capacity menu_highlights pic_name
      pic_role contacts services specialities doctor_count staff_names
      branch_count branches payment_methods insurance_accepted languages
      year_established company_size tags intents outreach_note decision_makers
      promos booking_channels completeness confidence crawl_status source
    ].freeze

    attr_reader :raw

    def initialize(raw_row, header_lookup)
      @raw = raw_row
      @lookup = header_lookup # header -> logical field string (or nil)
    end

    def name
      @raw['name'].to_s.strip.presence
    end

    # Best email: prefer the single `email` column, otherwise take the first
    # pipe/space separated entry from `emails`. Downcased.
    def email
      primary = @raw['email'].to_s.strip
      return primary.downcase if primary.match?(Devise.email_regexp)

      first = @raw['emails'].to_s.split(/[|\s]+/).map(&:strip).find { |e| e.match?(Devise.email_regexp) }
      first&.downcase
    end

    # Best phone: prefer phone_e164 (already E.164-ish), then phone.
    def phone_number
      candidate = @raw['phone_e164'].presence || @raw['phone'].presence
      return nil if candidate.blank?

      digits = candidate.gsub(/[^\d+]/, '')
      # Normalise to E.164 if it looks like a US/intl number missing the +.
      digits = "+#{digits}" unless digits.start_with?('+')
      digits if digits.match?(/\A\+[1-9]\d{1,14}\z/)
    end

    def website
      @raw['website'].to_s.strip.presence
    end

    def city
      @raw['city'].to_s.strip.presence
    end

    def country
      @raw['country'].to_s.strip.presence
    end

    def address
      @raw['address'].to_s.strip.presence
    end

    # Company is derived from the business `name` + `website` (domain).
    def company_name
      name
    end

    def company_domain
      return nil if website.blank?

      host = begin
        URI.parse(website).host
      rescue URI::InvalidURIError
        nil
      end
      host.presence
    end

    # Social links packed for custom attributes.
    def social_attributes
      {
        'website' => website,
        'instagram' => @raw['instagram'].to_s.strip.presence,
        'facebook' => @raw['facebook'].to_s.strip.presence,
        'linkedin' => @raw['linkedin'].to_s.strip.presence,
        'twitter' => @raw['twitter'].to_s.strip.presence,
        'youtube' => @raw['youtube'].to_s.strip.presence,
        'tiktok' => @raw['tiktok'].to_s.strip.presence
      }.compact
    end

    # All non-first-class columns, captured verbatim as custom attributes so
    # the full export is preserved on the contact.
    def extra_custom_attributes
      attrs = {}
      @raw.each do |header, value|
        logical = @lookup[header]
        next if logical.blank?

        key = logical.to_s
        next if %w[name email phone_number website city country address].include?(key)

        attrs[key] = value.to_s.strip
      end
      attrs.compact
    end

    def blank?
      name.blank? && email.blank? && phone_number.blank?
    end
  end
end
