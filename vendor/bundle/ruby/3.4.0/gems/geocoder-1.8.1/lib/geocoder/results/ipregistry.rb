require 'geocoder/results/base'

module Geocoder::Result
  class Ipregistry < Base

    def initialize(data)
      super

      @data = flatten_hash(data)
    end

    def coordinates
      [@data['location_latitude'], @data['location_longitude']]
    end

    def flatten_hash(hash)
      hash.each_with_object({}) do |(k, v), h|
        if v.is_a? Hash
          flatten_hash(v).map do |h_k, h_v|
            h["#{k}_#{h_k}".to_s] = h_v
          end
        else
          h[k] = v
        end
      end
    end

    private :flatten_hash

    def city
      @data['location_city']
    end

    def country
      @data['location_country_name']
    end

    def country_code
      @data['location_country_code']
    end

    def postal_code
      @data['location_postal']
    end

    def state
      @data['location_region_name']
    end

    def state_code
      @data['location_region_code']
    end

    # methods for fields specific to Ipregistry

    def ip
      @data["ip"]
    end

    def type
      @data["type"]
    end

    def hostname
      @data["hostname"]
    end

    def carrier_name
      @data["carrier_name"]
    end

    def carrier_mcc
      @data["carrier_mcc"]
    end

    def carrier_mnc
      @data["carrier_mnc"]
    end

    def connection_asn
      @data["connection_asn"]
    end

    def connection_domain
      @data["connection_domain"]
    end

    def connection_organization
      @data["connection_organization"]
    end

    def connection_type
      @data["connection_type"]
    end

    def currency_code
      @data["currency_code"]
    end

    def currency_name
      @data["currency_name"]
    end

    def currency_plural
      @data["currency_plural"]
    end

    def currency_symbol
      @data["currency_symbol"]
    end

    def currency_symbol_native
      @data["currency_symbol_native"]
    end

    def currency_format_negative_prefix
      @data["currency_format_negative_prefix"]
    end

    def currency_format_negative_suffix
      @data["currency_format_negative_suffix"]
    end

    def currency_format_positive_prefix
      @data["currency_format_positive_prefix"]
    end

    def currency_format_positive_suffix
      @data["currency_format_positive_suffix"]
    end

    def location_continent_code
      @data["location_continent_code"]
    end

    def location_continent_name
      @data["location_continent_name"]
    end

    def location_country_area
      @data["location_country_area"]
    end

    def location_country_borders
      @data["location_country_borders"]
    end

    def location_country_calling_code
      @data["location_country_calling_code"]
    end

    def location_country_capital
      @data["location_country_capital"]
    end

    def location_country_code
      @data["location_country_code"]
    end

    def location_country_name
      @data["location_country_name"]
    end

    def location_country_population
      @data["location_country_population"]
    end

    def location_country_population_density
      @data["location_country_population_density"]
    end

    def location_country_flag_emoji
      @data["location_country_flag_emoji"]
    end

    def location_country_flag_emoji_unicode
      @data["location_country_flag_emoji_unicode"]
    end

    def location_country_flag_emojitwo
      @data["location_country_flag_emojitwo"]
    end

    def location_country_flag_noto
      @data["location_country_flag_noto"]
    end

    def location_country_flag_twemoji
      @data["location_country_flag_twemoji"]
    end

    def location_country_flag_wikimedia
      @data["location_country_flag_wikimedia"]
    end

    def location_country_languages
      @data["location_country_languages"]
    end

    def location_country_tld
      @data["location_country_tld"]
    end

    def location_region_code
      @data["location_region_code"]
    end

    def location_region_name
      @data["location_region_name"]
    end

    def location_city
      @data["location_city"]
    end

    def location_postal
      @data["location_postal"]
    end

    def location_latitude
      @data["location_latitude"]
    end

    def location_longitude
      @data["location_longitude"]
    end

    def location_language_code
      @data["location_language_code"]
    end

    def location_language_name
      @data["location_language_name"]
    end

    def location_language_native
      @data["location_language_native"]
    end

    def location_in_eu
      @data["location_in_eu"]
    end

    def security_is_bogon
      @data["security_is_bogon"]
    end

    def security_is_cloud_provider
      @data["security_is_cloud_provider"]
    end

    def security_is_tor
      @data["security_is_tor"]
    end

    def security_is_tor_exit
      @data["security_is_tor_exit"]
    end

    def security_is_proxy
      @data["security_is_proxy"]
    end

    def security_is_anonymous
      @data["security_is_anonymous"]
    end

    def security_is_abuser
      @data["security_is_abuser"]
    end

    def security_is_attacker
      @data["security_is_attacker"]
    end

    def security_is_threat
      @data["security_is_threat"]
    end

    def time_zone_id
      @data["time_zone_id"]
    end

    def time_zone_abbreviation
      @data["time_zone_abbreviation"]
    end

    def time_zone_current_time
      @data["time_zone_current_time"]
    end

    def time_zone_name
      @data["time_zone_name"]
    end

    def time_zone_offset
      @data["time_zone_offset"]
    end

    def time_zone_in_daylight_saving
      @data["time_zone_in_daylight_saving"]
    end
  end
end
