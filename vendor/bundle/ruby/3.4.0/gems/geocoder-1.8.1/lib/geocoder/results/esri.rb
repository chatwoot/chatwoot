require 'geocoder/results/base'

module Geocoder::Result
  class Esri < Base

    def address
      address_key = reverse_geocode? ? 'Address' : 'Match_addr'
      attributes[address_key]
    end

    def city
      if !reverse_geocode? && is_city?
        place_name
      else
        attributes['City']
      end
    end

    def state
      attributes['Region']
    end

    def state_code
      abbr = attributes['RegionAbbr']
      abbr.to_s == "" ? state : abbr
    end

    def country
      country_key = reverse_geocode? ? "CountryCode" : "Country"
      attributes[country_key]
    end

    alias_method :country_code, :country

    def postal_code
      attributes['Postal']
    end

    def place_name
      place_name_key = reverse_geocode? ? "Address" : "PlaceName"
      attributes[place_name_key]
    end

    def place_type
      reverse_geocode? ? "Address" : attributes['Type']
    end

    def coordinates
      [geometry["y"], geometry["x"]]
    end

    def viewport
      north = attributes['Ymax']
      south = attributes['Ymin']
      east = attributes['Xmax']
      west = attributes['Xmin']
      [south, west, north, east]
    end

    private

    def attributes
      reverse_geocode? ? @data['address'] : @data['locations'].first['feature']['attributes']
    end

    def geometry
      reverse_geocode? ? @data["location"] : @data['locations'].first['feature']["geometry"]
    end

    def reverse_geocode?
      @data['locations'].nil?
    end

    def is_city?
      ['City', 'State Capital', 'National Capital'].include?(place_type)
    end
  end
end
