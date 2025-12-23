require 'geocoder/results/base'

module Geocoder::Result
  class Ipgeolocation < Base

    def coordinates
      [@data['latitude'].to_f, @data['longitude'].to_f]
    end

    def address(format = :full)
      "#{city}, #{state} #{postal_code}, #{country_name}".sub(/^[ ,]*/, "")
    end

    def state
      @data['state_prov']
    end

    def state_code
      @data['state_prov']
    end

    def country
      @data['country_name']
    end

    def country_code
      @data['country_code2']
    end

    def postal_code
      @data['zipcode']
    end

    def self.response_attributes
      [
          ['ip', ''],
          ['hostname', ''],
          ['continent_code', ''],
          ['continent_name', ''],
          ['country_code2', ''],
          ['country_code3', ''],
          ['country_name', ''],
          ['country_capital',''],
          ['district',''],
          ['state_prov',''],
          ['city', ''],
          ['zipcode', ''],
          ['time_zone', {}],
          ['currency', {}]
      ]
    end

    response_attributes.each do |attr, default|
      define_method attr do
        @data[attr] || default
      end
    end
  end
end
