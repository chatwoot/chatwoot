require 'geocoder/results/base'

module Geocoder::Result
  class Bing < Base

    def address(format = :full)
      @data['address']['formattedAddress']
    end

    def city
      @data['address']['locality']
    end

    def state_code
      @data['address']['adminDistrict']
    end

    alias_method :state, :state_code

    def country
      @data['address']['countryRegion']
    end

    alias_method :country_code, :country

    def postal_code
      @data['address']['postalCode'].to_s
    end

    def coordinates
      @data['point']['coordinates']
    end

    def address_data
      @data['address']
    end

    def viewport
      @data['bbox']
    end

    def self.response_attributes
      %w[bbox name confidence entityType]
    end

    response_attributes.each do |a|
      define_method a do
        @data[a]
      end
    end
  end
end
