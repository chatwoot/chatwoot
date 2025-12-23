require 'geocoder/results/base'

module Geocoder::Result
  class GeocoderCa < Base

    def coordinates
      [@data['latt'].to_f, @data['longt'].to_f]
    end

    def address(format = :full)
      "#{street_address}, #{city}, #{state} #{postal_code}, #{country}".sub(/^[ ,]*/, "")
    end

    def street_address
      "#{@data['stnumber']} #{@data['staddress']}"
    end

    def city
      @data['city'] or (@data['standard'] and @data['standard']['city']) or ""
    end

    def state
      @data['prov'] or (@data['standard'] and @data['standard']['prov']) or ""
    end

    alias_method :state_code, :state

    def postal_code
      @data['postal'] or (@data['standard'] and @data['standard']['postal']) or ""
    end

    def country
      country_code == 'CA' ? 'Canada' : 'United States'
    end

    def country_code
      return nil if state.nil? || state == ""
      canadian_province_abbreviations.include?(state) ? "CA" : "US"
    end

    def self.response_attributes
      %w[latt longt inlatt inlongt distance stnumber staddress prov
        NearRoad NearRoadDistance betweenRoad1 betweenRoad2
        intersection major_intersection]
    end

    response_attributes.each do |a|
      define_method a do
        @data[a]
      end
    end


    private # ----------------------------------------------------------------

    def canadian_province_abbreviations
      %w[ON QC NS NB MB BC PE SK AB NL]
    end
  end
end
