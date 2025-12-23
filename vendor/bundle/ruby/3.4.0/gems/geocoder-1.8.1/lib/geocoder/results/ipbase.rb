require 'geocoder/results/base'

module Geocoder::Result
  class Ipbase < Base
    def ip
      @data["data"]['ip']
    end

    def country_code
      @data["data"]["location"]["country"]["alpha2"]
    end

    def country
      @data["data"]["location"]["country"]["name"]
    end

    def state_code
      @data["data"]["location"]["region"]["alpha2"]
    end

    def state
      @data["data"]["location"]["region"]["name"]
    end

    def city
      @data["data"]["location"]["city"]["name"]
    end

    def postal_code
      @data["data"]["location"]["zip"]
    end

    def coordinates
      [
        @data["data"]["location"]["latitude"].to_f,
        @data["data"]["location"]["longitude"].to_f
      ]
    end
  end
end
