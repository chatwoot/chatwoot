require 'geocoder/results/base'

module Geocoder::Result
  class Telize < Base

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
      @data['country']
    end

    def country_code
      @data['country_code']
    end

    def postal_code
      @data['postal_code']
    end

    def self.response_attributes
      %w[timezone isp dma_code area_code ip asn continent_code country_code3]
    end

    response_attributes.each do |a|
      define_method a do
        @data[a]
      end
    end
  end
end
