require 'geocoder/results/base'

module Geocoder::Result
  class Pelias < Base
    def address(format = :full)
      properties['label']
    end

    def city
      locality
    end

    def coordinates
      geometry['coordinates'].reverse
    end

    def country_code
      properties['country_a']
    end

    def postal_code
      properties['postalcode'].to_s
    end

    def province
      state
    end

    def state
      properties['region']
    end

    def state_code
      properties['region_a']
    end

    def self.response_attributes
      %w[county confidence country gid id layer localadmin locality neighborhood]
    end

    response_attributes.each do |a|
      define_method a do
        properties[a]
      end
    end

    private

    def geometry
      @data.fetch('geometry', {})
    end

    def properties
      @data.fetch('properties', {})
    end
  end
end

