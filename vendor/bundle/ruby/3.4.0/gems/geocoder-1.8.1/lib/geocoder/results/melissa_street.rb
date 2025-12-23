require 'geocoder/results/base'

module Geocoder::Result
  class MelissaStreet < Base
    def address(format = :full)
      @data['FormattedAddress']
    end

    def street_address
      @data['AddressLine1']
    end

    def suffix
      @data['ThoroughfareTrailingType']
    end

    def number
      @data['PremisesNumber']
    end

    def city
      @data['Locality']
    end

    def state_code
      @data['AdministrativeArea']
    end
    alias_method :state, :state_code

    def country
      @data['CountryName']
    end

    def country_code
      @data['CountryISO3166_1_Alpha2']
    end

    def postal_code
      @data['PostalCode']
    end

    def coordinates
      [@data['Latitude'].to_f, @data['Longitude'].to_f]
    end
  end
end
