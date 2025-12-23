require 'geocoder/results/base'

module Geocoder::Result
  class Mapquest < Base

    def coordinates
      %w[lat lng].map{ |l| @data["latLng"][l] }
    end

    def city
      @data['adminArea5']
    end

    def street
      @data['street']
    end

    def state
      @data['adminArea3']
    end

    def county
      @data['adminArea4']
    end

    alias_method :state_code, :state

    #FIXME: these might not be right, unclear with MQ documentation
    alias_method :province, :state
    alias_method :province_code, :state

    def postal_code
      @data['postalCode'].to_s
    end

    def country
      @data['adminArea1']
    end

    def country_code
      country
    end

    def address
      [street, city, state, postal_code, country].reject{|s| s.length == 0 }.join(", ")
    end
  end
end
