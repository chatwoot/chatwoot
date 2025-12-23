require 'geocoder/results/base'

module Geocoder::Result
  class Ipstack < Base

    def address(format = :full)
      s = region_code.empty? ? "" : ", #{region_code}"
      "#{city}#{s} #{zip}, #{country_name}".sub(/^[ ,]*/, "")
    end

    def state
      @data['region_name']
    end

    def state_code
      @data['region_code']
    end

    def country
      @data['country_name']
    end

    def postal_code
      @data['zip'] || @data['zipcode'] || @data['zip_code']
    end

    def self.response_attributes
      [
        ['ip', ''],
        ['hostname', ''],
        ['continent_code', ''],
        ['continent_name', ''],
        ['country_code', ''],
        ['country_name', ''],
        ['region_code', ''],
        ['region_name', ''],
        ['city', ''],
        ['zip', ''],
        ['latitude', 0],
        ['longitude', 0],
        ['location', {}],
        ['time_zone', {}],
        ['currency', {}],
        ['connection', {}],
        ['security', {}],
      ]
    end

    response_attributes.each do |attr, default|
      define_method attr do
        @data[attr] || default
      end
    end

    def metro_code
      Geocoder.log(:warn, "Ipstack does not implement `metro_code` in api results.  Please discontinue use.")
      0 # no longer implemented by ipstack
    end
  end
end
