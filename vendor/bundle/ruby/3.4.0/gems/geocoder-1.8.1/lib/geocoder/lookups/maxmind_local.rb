require 'ipaddr'
require 'geocoder/lookups/base'
require 'geocoder/results/maxmind_local'

module Geocoder::Lookup
  class MaxmindLocal < Base

    def initialize
      if !configuration[:file].nil?
        begin
          gem = RUBY_PLATFORM == 'java' ? 'jgeoip' : 'geoip'
          require gem
        rescue LoadError
          raise "Could not load geoip dependency. To use MaxMind Local lookup you must add the #{gem} gem to your Gemfile or have it installed in your system."
        end
      end
      super
    end

    def name
      "MaxMind Local"
    end

    def required_api_key_parts
      []
    end

    private

    def results(query)
      if configuration[:file]
        geoip_class = RUBY_PLATFORM == "java" ? JGeoIP : GeoIP
        geoip_instance = geoip_class.new(configuration[:file])
        result =
          if configuration[:package] == :country
            geoip_instance.country(query.to_s)
          else
            geoip_instance.city(query.to_s)
          end
        result.nil? ? [] : [encode_hash(result.to_hash)]
      elsif configuration[:package] == :city
        addr = IPAddr.new(query.text).to_i
        q = "SELECT l.country, l.region, l.city, l.latitude, l.longitude
          FROM maxmind_geolite_city_location l WHERE l.loc_id = (SELECT b.loc_id FROM maxmind_geolite_city_blocks b
          WHERE b.start_ip_num <= #{addr} AND #{addr} <= b.end_ip_num)"
        format_result(q, [:country_name, :region_name, :city_name, :latitude, :longitude])
      elsif configuration[:package] == :country
        addr = IPAddr.new(query.text).to_i
        q = "SELECT country, country_code FROM maxmind_geolite_country
          WHERE start_ip_num <= #{addr} AND #{addr} <= end_ip_num"
        format_result(q, [:country_name, :country_code2])
      end
    end

    def encode_hash(hash, encoding = "UTF-8")
      hash.inject({}) do |h,i|
        h[i[0]] = i[1].is_a?(String) ? i[1].encode(encoding) : i[1]
        h
      end
    end

    def format_result(query, attr_names)
      if r = ActiveRecord::Base.connection.execute(query).first
        r = r.values if r.is_a?(Hash) # some db adapters return Hash, some Array
        [Hash[*attr_names.zip(r).flatten]]
      else
        []
      end
    end
  end
end
