require 'geocoder/results/base'

module Geocoder::Result
  class Osmnames < Base
    def address
      @data['display_name']
    end

    def coordinates
      [@data['lat'].to_f, @data['lon'].to_f]
    end

    def viewport
      west, south, east, north = @data['boundingbox'].map(&:to_f)
      [south, west, north, east]
    end

    def state
      @data['state']
    end
    alias_method :state_code, :state

    def place_class
      @data['class']
    end

    def place_type
      @data['type']
    end

    def postal_code
      ''
    end

    def country_code
      @data['country_code']
    end

    def country
      @data['country']
    end

    def self.response_attributes
      %w[house_number street city name osm_id osm_type boundingbox place_rank
      importance county rank name_suffix]
    end

    response_attributes.each do |a|
      unless method_defined?(a)
        define_method a do
          @data[a]
        end
      end
    end
  end
end
