require 'geocoder/results/base'

module Geocoder::Result
  class Baidu < Base

    def coordinates
      ['lat', 'lng'].map{ |i| @data['location'][i] }
    end

    def province
      @data['addressComponent'] and @data['addressComponent']['province'] or ""
    end

    alias_method :state, :province

    def city
      @data['addressComponent'] and @data['addressComponent']['city'] or ""
    end

    def district
      @data['addressComponent'] and @data['addressComponent']['district'] or ""
    end

    def street
      @data['addressComponent'] and @data['addressComponent']['street'] or ""
    end

    def street_number
      @data['addressComponent'] and @data['addressComponent']['street_number']
    end

    def formatted_address
      @data['formatted_address'] or ""
    end

    alias_method :address, :formatted_address

    def address_components
      @data['addressComponent']
    end

    def state_code
      ""
    end

    def postal_code
      ""
    end

    def country
      "China"
    end

    def country_code
      "CN"
    end

    ##
    # Get address components of a given type. Valid types are defined in
    # Baidu's Geocoding API documentation and include (among others):
    #
    #   :business
    #   :cityCode
    #
    def self.response_attributes
      %w[business cityCode]
    end

    response_attributes.each do |a|
      define_method a do
        @data[a]
      end
    end
  end
end
