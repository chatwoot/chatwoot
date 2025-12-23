# frozen_string_literal: true

require 'geocoder/lookups/base'
require 'geocoder/results/geoapify'

module Geocoder
  module Lookup
    # https://apidocs.geoapify.com/docs/geocoding/api
    class Geoapify < Base
      def name
        'Geoapify'
      end

      def required_api_key_parts
        ['api_key']
      end

      def supported_protocols
        [:https]
      end

      private

      def base_query_url(query)
        method = if query.reverse_geocode?
          'reverse'
        elsif query.options[:autocomplete]
          'autocomplete'
        else
          'search'
        end
        "https://api.geoapify.com/v1/geocode/#{method}?"
      end

      def results(query)
        return [] unless (doc = fetch_data(query))

        # The rest of the status codes should be already handled by the default
        # functionality as the API returns correct HTTP response codes in most
        # cases. There may be some unhandled cases still (such as over query
        # limit reached) but there is not enough documentation to cover them.
        case doc['statusCode']
        when 500
          raise_error(Geocoder::InvalidRequest) || Geocoder.log(:warn, doc['message'])
        end

        return [] unless doc['type'] == 'FeatureCollection'
        return [] unless doc['features'] || doc['features'].present?

        doc['features']
      end

      def query_url_params(query)
        lang = query.language || configuration.language
        params = { apiKey: configuration.api_key, lang: lang, limit: query.options[:limit] }

        if query.reverse_geocode?
          params.merge!(query_url_params_reverse(query))
        else
          params.merge!(query_url_params_coordinates(query))
        end

        params.merge!(super)
      end

      def query_url_params_coordinates(query)
        { text: query.sanitized_text }
      end

      def query_url_params_reverse(query)
        {
          lat: query.coordinates[0],
          lon: query.coordinates[1]
        }
      end
    end
  end
end
