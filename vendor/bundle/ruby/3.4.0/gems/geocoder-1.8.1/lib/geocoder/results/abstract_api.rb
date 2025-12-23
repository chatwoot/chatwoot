require 'geocoder/results/base'

module Geocoder
  module Result
    class AbstractApi < Base

      ##
      # Geolocation

      def state
        @data['region']
      end

      def state_code
        @data['region_iso_code']
      end

      def city
        @data["city"]
      end

      def city_geoname_id
        @data["city_geoname_id"]
      end

      def region_geoname_id
        @data["region_geoname_id"]
      end

      def postal_code
        @data["postal_code"]
      end

      def country
        @data["country"]
      end

      def country_code
        @data["country_code"]
      end

      def country_geoname_id
        @data["country_geoname_id"]
      end

      def country_is_eu
        @data["country_is_eu"]
      end

      def continent
        @data["continent"]
      end

      def continent_code
        @data["continent_code"]
      end

      def continent_geoname_id
        @data["continent_geoname_id"]
      end

      ##
      # Security

      def is_vpn?
        @data.dig "security", "is_vpn"
      end

      ##
      # Timezone

      def timezone_name
        @data.dig "timezone", "name"
      end

      def timezone_abbreviation
        @data.dig "timezone", "abbreviation"
      end

      def timezone_gmt_offset
        @data.dig "timezone", "gmt_offset"
      end

      def timezone_current_time
        @data.dig "timezone", "current_time"
      end

      def timezone_is_dst
        @data.dig "timezone", "is_dst"
      end

      ##
      # Flag

      def flag_emoji
        @data.dig "flag", "emoji"
      end

      def flag_unicode
        @data.dig "flag", "unicode"
      end

      def flag_png
        @data.dig "flag", "png"
      end

      def flag_svg
        @data.dig "flag", "svg"
      end

      ##
      # Currency

      def currency_currency_name
        @data.dig "currency", "currency_name"
      end

      def currency_currency_code
        @data.dig "currency", "currency_code"
      end

      ##
      # Connection

      def connection_autonomous_system_number
        @data.dig "connection", "autonomous_system_number"
      end

      def connection_autonomous_system_organization
        @data.dig "connection", "autonomous_system_organization"
      end

      def connection_connection_type
        @data.dig "connection", "connection_type"
      end

      def connection_isp_name
        @data.dig "connection", "isp_name"
      end

      def connection_organization_name
        @data.dig "connection", "organization_name"
      end
    end
  end
end