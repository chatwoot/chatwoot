require 'geocoder/lookups/base'

module Geocoder::Result
  class SmartyStreets < Base
    def coordinates
      result = %w(latitude longitude).map do |i|
        zipcode_endpoint? ? zipcodes.first[i] : metadata[i]
      end

      if result.compact.empty?
        nil
      else
        result
      end
    end

    def address
      parts =
        if international_endpoint?
          (1..12).map { |i| @data["address#{i}"] }
        else
          [
            delivery_line_1,
            delivery_line_2,
            last_line
          ]
        end
      parts.select{ |i| i.to_s != "" }.join(" ")
    end

    def state
      if international_endpoint?
        components['administrative_area']
      elsif zipcode_endpoint?
        city_states.first['state']
      else
        components['state_abbreviation']
      end
    end

    def state_code
      if international_endpoint?
        components['administrative_area']
      elsif zipcode_endpoint?
        city_states.first['state_abbreviation']
      else
        components['state_abbreviation']
      end
    end

    def country
      international_endpoint? ?
        components['country_iso_3'] :
        "United States"
    end

    def country_code
      international_endpoint? ?
        components['country_iso_3'] :
        "US"
    end

    ## Extra methods not in base.rb ------------------------

    def street
      international_endpoint? ?
        components['thoroughfare_name'] :
        components['street_name']
    end

    def city
      if international_endpoint?
        components['locality']
      elsif zipcode_endpoint?
        city_states.first['city']
      else
        components['city_name']
      end
    end

    def zipcode
      if international_endpoint?
        components['postal_code']
      elsif zipcode_endpoint?
        zipcodes.first['zipcode']
      else
        components['zipcode']
      end
    end
    alias_method :postal_code, :zipcode

    def zip4
      components['plus4_code']
    end
    alias_method :postal_code_extended, :zip4

    def fips
      zipcode_endpoint? ?
        zipcodes.first['county_fips'] :
        metadata['county_fips']
    end

    def zipcode_endpoint?
      zipcodes.any?
    end

    def international_endpoint?
      !@data['address1'].nil?
    end

    [
      :delivery_line_1,
      :delivery_line_2,
      :last_line,
      :delivery_point_barcode,
      :addressee
    ].each do |m|
      define_method(m) do
        @data[m.to_s] || ''
      end
    end

    [
      :components,
      :metadata,
      :analysis
    ].each do |m|
      define_method(m) do
        @data[m.to_s] || {}
      end
    end

    [
      :city_states,
      :zipcodes
    ].each do |m|
      define_method(m) do
        @data[m.to_s] || []
      end
    end
  end
end
