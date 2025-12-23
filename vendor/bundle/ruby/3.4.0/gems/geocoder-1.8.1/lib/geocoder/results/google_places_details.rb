require "geocoder/results/google"

module Geocoder
  module Result
    class GooglePlacesDetails < Google
      def place_id
        @data["place_id"]
      end

      def types
        @data["types"] || []
      end

      def reviews
        @data["reviews"] || []
      end

      def rating
        @data["rating"]
      end

      def rating_count
        @data["user_ratings_total"]
      end

      def phone_number
        @data["international_phone_number"]
      end

      def website
        @data["website"]
      end

      def photos
        @data["photos"]
      end
    end
  end
end
