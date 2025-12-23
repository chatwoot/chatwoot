require 'geocoder/results/base'

module Geocoder::Result
  class IpapiCom < Base

    def coordinates
      [lat, lon]
    end

    def address
      "#{city}, #{state_code} #{postal_code}, #{country}".sub(/^[ ,]*/, "")
    end

    def state
      region_name
    end

    def state_code
      region
    end

    def postal_code
      zip
    end

    def country_code
      @data['countryCode']
    end

    def region_name
      @data['regionName']
    end

    def self.response_attributes
      %w[country region city zip timezone isp org as reverse query status message mobile proxy lat lon]
    end

    response_attributes.each do |attribute|
      define_method attribute do
        @data[attribute]
      end
    end

  end
end
