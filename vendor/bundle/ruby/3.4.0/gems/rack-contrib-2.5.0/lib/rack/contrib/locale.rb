# frozen_string_literal: true

require 'i18n'

module Rack
  class Locale
    HEADERS_KLASS = Rack.release < "3" ? Utils::HeaderHash : Headers
    private_constant :HEADERS_KLASS

    def initialize(app)
      @app = app
    end

    def call(env)
      locale_to_restore = I18n.locale

      locale = user_preferred_locale(env["HTTP_ACCEPT_LANGUAGE"])
      locale ||= I18n.default_locale

      env['rack.locale'] = I18n.locale = locale.to_s
      status, headers, body = @app.call(env)
      headers = HEADERS_KLASS.new.merge(headers)

      unless headers['Content-Language']
        headers['Content-Language'] = locale.to_s
      end

      [status, headers, body]
    ensure
      I18n.locale = locale_to_restore
    end

    private

    # Accept-Language header is covered mainly by RFC 7231
    # https://tools.ietf.org/html/rfc7231
    #
    # Related sections:
    #
    # * https://tools.ietf.org/html/rfc7231#section-5.3.1
    # * https://tools.ietf.org/html/rfc7231#section-5.3.5
    # * https://tools.ietf.org/html/rfc4647#section-3.4
    #
    # There is an obsolete RFC 2616 (https://tools.ietf.org/html/rfc2616)
    #
    # Edge cases:
    #
    # * Value can be a comma separated list with optional whitespaces:
    #   Accept-Language: da, en-gb;q=0.8, en;q=0.7
    #
    # * Quality value can contain optional whitespaces as well:
    #   Accept-Language: ru-UA, ru; q=0.8, uk; q=0.6, en-US; q=0.4, en; q=0.2
    #
    # * Quality prefix 'q=' can be in upper case (Q=)
    #
    # * Ignore case when match locale with I18n available locales
    #
    def user_preferred_locale(header)
      return if header.nil?

      locales = header.gsub(/\s+/, '').split(",").map do |language_tag|
        locale, quality = language_tag.split(/;q=/i)
        quality = quality ? quality.to_f : 1.0
        [locale, quality]
      end.reject do |(locale, quality)|
        locale == '*' || quality == 0
      end.sort_by do |(_, quality)|
        quality
      end.map(&:first)

      return if locales.empty?

      if I18n.enforce_available_locales
        locale = locales.reverse.find { |locale| I18n.available_locales.any? { |al| match?(al, locale) } }
        matched_locale = I18n.available_locales.find { |al| match?(al, locale) } if locale
        if !locale && !matched_locale
          matched_locale = locales.reverse.find { |locale| I18n.available_locales.any? { |al| variant_match?(al, locale) } }
          matched_locale = matched_locale[0,2] if matched_locale
        end
        matched_locale
      else
        locales.last
      end
    end

    def match?(s1, s2)
      s1.to_s.casecmp(s2.to_s) == 0
    end

    def variant_match?(s1, s2)
      s1.to_s.casecmp(s2[0,2].to_s) == 0
    end
  end
end
