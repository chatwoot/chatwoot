require 'geocoder/results/base'

module Geocoder::Result
  class Nominatim < Base

    def poi
      return address_data[place_type] if address_data.key?(place_type)
      return nil
    end

    def house_number
      address_data['house_number']
    end

    def address
      @data['display_name']
    end

    def street
      %w[road pedestrian highway].each do |key|
        return address_data[key] if address_data.key?(key)
      end
      return nil
    end

    def city
      %w[city town village hamlet].each do |key|
        return address_data[key] if address_data.key?(key)
      end
      return nil
    end

    def village
      address_data['village']
    end

    def town
      address_data['town']
    end

    def state
      address_data['state']
    end

    alias_method :state_code, :state

    def postal_code
      address_data['postcode']
    end

    def county
      address_data['county']
    end

    def country
      address_data['country']
    end

    def country_code
      address_data['country_code']
    end

    def suburb
      address_data['suburb']
    end

    def city_district
      address_data['city_district']
    end

    def state_district
      address_data['state_district']
    end

    def neighbourhood
      address_data['neighbourhood']
    end

    def municipality
      address_data['municipality']
    end

    def coordinates
      return [] unless @data['lat'] && @data['lon']

      [@data['lat'].to_f, @data['lon'].to_f]
    end

    def place_class
      @data['class']
    end

    def place_type
      @data['type']
    end

    def viewport
      south, north, west, east = @data['boundingbox'].map(&:to_f)
      [south, west, north, east]
    end

    def self.response_attributes
      %w[place_id osm_type osm_id boundingbox license
         polygonpoints display_name class type stadium]
    end

    response_attributes.each do |a|
      unless method_defined?(a)
        define_method a do
          @data[a]
        end
      end
    end

    private

    def address_data
      @data['address'] || {}
    end
  end
end
