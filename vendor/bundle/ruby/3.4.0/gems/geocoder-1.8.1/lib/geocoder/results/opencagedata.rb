require 'geocoder/results/base'

module Geocoder::Result
  class Opencagedata < Base

    def poi
      %w[stadium bus_stop tram_stop].each do |key|
        return @data['components'][key] if @data['components'].key?(key)
      end
      return nil
    end

    def house_number
      @data['components']['house_number']
    end

    def address
      @data['formatted']
    end

    def street
      %w[road pedestrian highway].each do |key|
        return @data['components'][key] if @data['components'].key?(key)
      end
      return nil
    end

    def city
      %w[city town village hamlet].each do |key|
        return @data['components'][key] if @data['components'].key?(key)
      end
      return nil
    end

    def village
      @data['components']['village']
    end

    def state
      @data['components']['state']
    end

    def state_code
      @data['components']['state_code']
    end

    def postal_code
      @data['components']['postcode'].to_s
    end

    def county
      @data['components']['county']
    end

    def country
      @data['components']['country']
    end

    def country_code
      @data['components']['country_code']
    end

    def suburb
      @data['components']['suburb']
    end

    def coordinates
      [@data['geometry']['lat'].to_f, @data['geometry']['lng'].to_f]
    end

    def viewport
      bounds = @data['bounds'] || fail
      south, west = %w(lat lng).map { |i| bounds['southwest'][i] }
      north, east = %w(lat lng).map { |i| bounds['northeast'][i] }
      [south, west, north, east]
    end

    def time_zone
      # The OpenCage API documentation states that `annotations` is available
      # "when possible" https://geocoder.opencagedata.com/api#annotations
      @data
        .fetch('annotations', {})
        .fetch('timezone', {})
        .fetch('name', nil)
    end

    def self.response_attributes
      %w[boundingbox license 
        formatted stadium]
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
