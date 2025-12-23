# frozen_string_literal: true

require 'geocoder/results/base'

module Geocoder
  module Result
    # https://apidocs.geoapify.com/docs/geocoding/api
    class Geoapify < Base
      def address(_format = :full)
        properties['formatted']
      end

      def address_line1
        properties['address_line1']
      end

      def address_line2
        properties['address_line2']
      end

      def house_number
        properties['housenumber']
      end

      def street
        properties['street']
      end

      def postal_code
        properties['postcode']
      end

      def district
        properties['district']
      end

      def suburb
        properties['suburb']
      end

      def city
        properties['city']
      end

      def county
        properties['county']
      end

      def state
        properties['state']
      end

      # Not currently available in the API
      def state_code
        ''
      end

      def country
        properties['country']
      end

      def country_code
        return unless properties['country_code']

        properties['country_code'].upcase
      end

      def coordinates
        return unless properties['lat']
        return unless properties['lon']

        [properties['lat'], properties['lon']]
      end

      # See: https://tools.ietf.org/html/rfc7946#section-3.1
      #
      # Each feature has a "Point" type in the Geoapify API.
      def geometry
        return unless data['geometry']

        symbol_hash data['geometry']
      end

      # See: https://tools.ietf.org/html/rfc7946#section-5
      def bounds
        data['bbox']
      end

      # Type of the result, one of:
      #
      #   * :unknown
      #   * :amenity
      #   * :building
      #   * :street
      #   * :suburb
      #   * :district
      #   * :postcode
      #   * :city
      #   * :county
      #   * :state
      #   * :country
      #
      def type
        return :unknown unless properties['result_type']

        properties['result_type'].to_sym
      end

      # Distance in meters to given bias:proximity or to given coordinates for
      # reverse geocoding
      def distance
        properties['distance']
      end

      # Calculated rank for the result, containing the following keys:
      #
      #   * `popularity` - The popularity score of the result
      #   * `confidence` - The confidence value of the result (0-1)
      #   * `match_type` - The result's match type, one of following:
      #      * full_match
      #      * inner_part
      #      * match_by_building
      #      * match_by_street
      #      * match_by_postcode
      #      * match_by_city_or_disrict
      #      * match_by_country_or_state
      #
      # Example:
      #   {
      #     popularity: 8.615793062435909,
      #     confidence: 0.88,
      #     match_type: :full_match
      #   }
      def rank
        return unless properties['rank']

        r = symbol_hash(properties['rank'])
        r[:match_type] = r[:match_type].to_sym if r[:match_type]
        r
      end

      # Examples:
      #
      # Open
      #   {
      #     sourcename: 'openstreetmap',
      #     wheelchair: 'limited',
      #     wikidata: 'Q186125',
      #     wikipedia: 'en:Madison Square Garden',
      #     website: 'http://www.thegarden.com/',
      #     phone: '12124656741',
      #     osm_type: 'W',
      #     osm_id: 138141251,
      #     continent: 'North America',
      #   }
      def datasource
        return unless properties['datasource']

        symbol_hash properties['datasource']
      end

      private

      def properties
        @properties ||= data['properties'] || {}
      end

      def symbol_hash(orig_hash)
        {}.tap do |result|
          orig_hash.each_key do |key|
            next unless orig_hash[key]

            result[key.to_sym] = orig_hash[key]
          end
        end
      end
    end
  end
end
