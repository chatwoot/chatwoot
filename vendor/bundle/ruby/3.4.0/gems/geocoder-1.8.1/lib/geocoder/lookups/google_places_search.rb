require "geocoder/lookups/google"
require "geocoder/results/google_places_search"

module Geocoder
  module Lookup
    class GooglePlacesSearch < Google
      def name
        "Google Places Search"
      end

      def required_api_key_parts
        ["key"]
      end

      def supported_protocols
        [:https]
      end

      private

      def result_root_attr
        'candidates'
      end

      def base_query_url(query)
        "#{protocol}://maps.googleapis.com/maps/api/place/findplacefromtext/json?"
      end

      def query_url_google_params(query)
        {
          input: query.text,
          inputtype: 'textquery',
          fields: fields(query),
          locationbias: locationbias(query),
          language: query.language || configuration.language
        }
      end

      def fields(query)
        if query.options.has_key?(:fields)
          return format_fields(query.options[:fields])
        end

        if configuration.has_key?(:fields)
          return format_fields(configuration[:fields])
        end

        default_fields
      end

      def default_fields
        legacy = %w[id reference]
        basic = %w[business_status formatted_address geometry icon name 
          photos place_id plus_code types]
        contact = %w[opening_hours]
        atmosphere = %W[price_level rating user_ratings_total]
        format_fields(legacy, basic, contact, atmosphere)
      end

      def format_fields(*fields)
        flattened = fields.flatten.compact
        return if flattened.empty?

        flattened.join(',')
      end

      def locationbias(query)
        if query.options.has_key?(:locationbias)
          query.options[:locationbias]
        else
          configuration[:locationbias]
        end
      end
    end
  end
end
