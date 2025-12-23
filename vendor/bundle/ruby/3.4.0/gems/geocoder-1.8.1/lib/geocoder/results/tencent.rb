require 'geocoder/results/base'

module Geocoder::Result
  class Tencent < Base

    def coordinates
      ['lat', 'lng'].map{ |i| @data['location'][i] }
    end

    def address
      "#{province}#{city}#{district}#{street}#{street_number}"

      #@data['title'] or @data['address']
    end

    # NOTE: The Tencent reverse geocoding API has the field named
    # 'address_component' compared to 'address_components' in the 
    # regular geocoding API.
    def province
      @data['address_components'] and (@data['address_components']['province']) or 
      (@data['address_component'] and @data['address_component']['province']) or
      ""
    end

    alias_method :state, :province

    def city
      @data['address_components'] and (@data['address_components']['city']) or 
      (@data['address_component'] and @data['address_component']['city']) or
      ""
    end

    def district
      @data['address_components'] and (@data['address_components']['district']) or 
      (@data['address_component'] and @data['address_component']['district']) or
      ""
    end

    def street
      @data['address_components'] and (@data['address_components']['street']) or 
      (@data['address_component'] and @data['address_component']['street']) or
      ""
    end

    def street_number
      @data['address_components'] and (@data['address_components']['street_number']) or 
      (@data['address_component'] and @data['address_component']['street_number']) or
      ""
    end

    def address_components
      @data['address_components'] or @data['address_component']
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

  end
end