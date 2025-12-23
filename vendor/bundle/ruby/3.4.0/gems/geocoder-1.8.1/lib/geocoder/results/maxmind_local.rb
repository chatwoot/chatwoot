require 'geocoder/results/base'

module Geocoder::Result
  class MaxmindLocal < Base

    def coordinates
      [@data[:latitude], @data[:longitude]]
    end

    def city
      @data[:city_name]
    end

    def state
      @data[:region_name]
    end

    def state_code
      "" # Not available in Maxmind's database
    end

    def country
      @data[:country_name]
    end

    def country_code
      @data[:country_code2]
    end

    def postal_code
      @data[:postal_code]
    end

    def self.response_attributes
      %w[ip]
    end

    response_attributes.each do |a|
      define_method a do
        @data[a]
      end
    end
  end
end
