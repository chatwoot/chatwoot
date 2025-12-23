require 'geocoder/results/base'

module Geocoder::Result
  class BaiduIp < Base
    def coordinates
      [point['y'].to_f, point['x'].to_f]
    end

    def address
      @data['address']
    end

    def state
      province
    end

    def province
      address_detail['province']
    end

    def city
      address_detail['city']
    end

    def district
      address_detail['district']
    end

    def street
      address_detail['street']
    end

    def street_number
      address_detail['street_number']
    end

    def state_code
      ""
    end

    def postal_code
      ""
    end

    def country
      "China"
    end

    def country_code
      "CN"
    end

    private
    def address_detail
      @data['address_detail']
    end

    def point
      @data['point']
    end
  end
end
