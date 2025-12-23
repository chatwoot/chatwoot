module Geocoder
  module Result
    class Base

      # data (hash) fetched from geocoding service
      attr_accessor :data

      # true if result came from cache, false if from request to geocoding
      # service; nil if cache is not configured
      attr_accessor :cache_hit

      ##
      # Takes a hash of data from a parsed geocoding service response.
      #
      def initialize(data)
        @data = data
        @cache_hit = nil
      end

      ##
      # A string in the given format.
      #
      # This default implementation dumbly follows the United States address
      # format and will return incorrect results for most countries. Some APIs
      # return properly formatted addresses and those should be funneled
      # through this method.
      #
      def address(format = :full)
        if state_code.to_s != ""
          s = ", #{state_code}"
        elsif state.to_s != ""
          s = ", #{state}"
        else
          s = ""
        end
        "#{city}#{s} #{postal_code}, #{country}".sub(/^[ ,]*/, '')
      end

      ##
      # A two-element array: [lat, lon].
      #
      def coordinates
        [@data['latitude'].to_f, @data['longitude'].to_f]
      end

      def latitude
        coordinates[0]
      end

      def longitude
        coordinates[1]
      end

      def state
        fail
      end

      def province
        state
      end

      def state_code
        fail
      end

      def province_code
        state_code
      end

      def country
        fail
      end

      def country_code
        fail
      end
    end
  end
end
