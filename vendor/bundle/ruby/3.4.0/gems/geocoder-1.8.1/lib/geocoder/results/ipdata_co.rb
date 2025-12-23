require 'geocoder/results/base'

module Geocoder::Result
  class IpdataCo < Base

    def city
      @data['city']
    end

    def state
      @data['region']
    end

    def state_code
      @data['region_code']
    end

    def country
      @data['country_name']
    end

    def country_code
      @data['country_code']
    end

    def postal_code
      @data['postal']
    end

    def self.response_attributes
      %w[ip asn organisation currency currency_symbol calling_code flag time_zone is_eu]
    end

    response_attributes.each do |a|
      define_method a do
        @data[a]
      end
    end
  end
end
