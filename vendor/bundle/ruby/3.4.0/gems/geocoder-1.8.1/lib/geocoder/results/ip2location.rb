require 'geocoder/results/base'

module Geocoder::Result
  class Ip2location < Base

    def address(format = :full)
      "#{city_name} #{zip_code}, #{country_name}".sub(/^[ ,]*/, '')
    end

    def self.response_attributes
      %w[country_code country_name region_name city_name latitude longitude
        zip_code time_zone isp domain net_speed idd_code area_code usage_type
        weather_station_code weather_station_name mcc mnc mobile_brand elevation]
    end

    response_attributes.each do |attr|
      define_method attr do
        @data[attr] || ""
      end
    end
  end
end
