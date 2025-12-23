require 'geocoder/results/base'

module Geocoder::Result
  class Amap < Base

    def coordinates
      location = @data['location'] || @data['roadinters'].try(:first).try(:[], 'location') \
        || address_components.try(:[], 'streetNumber').try(:[], 'location')
      location.to_s.split(",").reverse.map(&:to_f)
    end

    def address
      formatted_address
    end

    def state
      province
    end

    def province
      address_components['province']
    end

    def city
      address_components['city'] == [] ? province : address_components["city"]
    end

    def district
      address_components['district']
    end

    def street
      if address_components["neighborhood"]["name"] != []
        return address_components["neighborhood"]["name"]
      elsif address_components['township'] != []
        return address_components["township"]
      else
        return @data['street'] || address_components['streetNumber'].try(:[], 'street')
      end
    end

    def street_number
      @data['number'] || address_components['streetNumber'].try(:[], 'number')
    end

    def formatted_address
      @data['formatted_address']
    end

    def address_components
      @data['addressComponent'] || @data
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
      %w[roads pois roadinters]
    end

    response_attributes.each do |a|
      define_method a do
        @data[a]
      end
    end
  end
end