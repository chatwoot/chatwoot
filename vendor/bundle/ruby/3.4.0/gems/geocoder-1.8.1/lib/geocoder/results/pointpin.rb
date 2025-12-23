require 'geocoder/results/base'

module Geocoder::Result
  class Pointpin < Base

    def address
      [ city_name, state, postal_code, country ].select{ |i| i.to_s != "" }.join(", ")
    end

    def city
      @data['city_name']
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
      @data['postcode']
    end

    def self.response_attributes
      %w[continent_code ip country_code country_name region_name city_name postcode latitude longitude time_zone languages]
    end

    response_attributes.each do |a|
      define_method a do
        @data[a]
      end
    end
  end
end
