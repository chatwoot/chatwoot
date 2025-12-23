require 'geocoder/results/base'
require 'easting_northing'

module Geocoder::Result
  class UkOrdnanceSurveyNames < Base

    def coordinates
      @coordinates ||= Geocoder::EastingNorthing.new(
        easting: data['GEOMETRY_X'],
        northing: data['GEOMETRY_Y'],
      ).lat_lng
    end

    def city
      is_postcode? ? data['DISTRICT_BOROUGH'] : data['NAME1']
    end

    def county
      data['COUNTY_UNITARY']
    end
    alias state county

    def county_code
      code_from_uri data['COUNTY_UNITARY_URI']
    end
    alias state_code county_code

    def province
      data['REGION']
    end

    def province_code
      code_from_uri data['REGION_URI']
    end

    def postal_code
      is_postcode? ? data['NAME1'] : ''
    end

    def country
      'United Kingdom'
    end

    def country_code
      'UK'
    end

    private

    def is_postcode?
      data['LOCAL_TYPE'] == 'Postcode'
    end

    def code_from_uri(uri)
      return '' if uri.nil?
      uri.split('/').last
    end
  end
end
