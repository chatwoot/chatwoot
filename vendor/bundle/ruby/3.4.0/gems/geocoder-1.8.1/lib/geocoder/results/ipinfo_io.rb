require 'geocoder/results/base'

module Geocoder::Result
  class IpinfoIo < Base

    def address(format = :full)
      "#{city} #{postal_code}, #{country}".sub(/^[ ,]*/, "")
    end

    def coordinates
      @data['loc'].to_s.split(",").map(&:to_f)
    end

    def city
      @data['city']
    end

    def state
      @data['region']
    end

    def country
      @data['country']
    end

    def postal_code
      @data['postal']
    end

    def country_code
      @data.fetch('country', '')
    end

    def state_code
      @data.fetch('region_code', '')
    end

    def self.response_attributes
      %w(ip region postal)
    end

    response_attributes.each do |a|
      define_method a do
        @data[a]
      end
    end
  end
end
