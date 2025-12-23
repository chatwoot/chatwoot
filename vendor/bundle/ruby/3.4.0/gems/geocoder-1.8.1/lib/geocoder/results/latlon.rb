require 'geocoder/results/base'

module Geocoder::Result
  class Latlon < Base

    def city
      address_components["city"]
    end

    def coordinates
      [@data['lat'].to_f, @data['lon'].to_f]
    end

    def country
      "United States" # LatLon.io only supports the US
    end

    def country_code
      "US" # LatLon.io only supports the US
    end

    def formatted_address(format = :full)
      address_components["address"]
    end
    alias_method :address, :formatted_address

    def number
      address_components["number"]
    end

    def prefix
      address_components["prefix"]
    end

    def state
      address_components["state"]
    end
    alias_method :state_code, :state

    def street
      [street_name, street_type].compact.join(' ')
    end

    def street_name
      address_components["street_name"]
    end

    def street_type
      address_components["street_type"]
    end

    def suffix
      address_components["suffix"]
    end

    def unit
      address_components["unit"]
    end

    def zip
      address_components["zip"]
    end
    alias_method :postal_code, :zip

    private

    def address_components
      @data["address"] || {}
    end
  end
end
