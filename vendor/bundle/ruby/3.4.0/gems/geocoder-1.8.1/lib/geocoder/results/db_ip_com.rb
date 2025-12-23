require 'geocoder/results/base'

module Geocoder::Result
  class DbIpCom < Base

    def coordinates
      ['latitude', 'longitude'].map{ |coordinate_name| @data[coordinate_name] }
    end

    def city
      @data['city']
    end

    def district
      @data['district']
    end

    def state_code
      @data['stateProvCode']
    end
    alias_method :state, :state_code

    def zip_code
      @data['zipCode']
    end
    alias_method :postal_code, :zip_code

    def country_name
      @data['countryName']
    end
    alias_method :country, :country_name

    def country_code
      @data['countryCode']
    end

    def continent_name
      @data['continentName']
    end
    alias_method :continent, :continent_name

    def continent_code
      @data['continentCode']
    end

    def time_zone
      @data['timeZone']
    end

    def gmt_offset
      @data['gmtOffset']
    end

    def currency_code
      @data['currencyCode']
    end
  end
end
