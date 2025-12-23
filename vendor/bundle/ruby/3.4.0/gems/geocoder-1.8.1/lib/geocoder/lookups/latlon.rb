require 'geocoder/lookups/base'
require 'geocoder/results/latlon'

module Geocoder::Lookup
  class Latlon < Base

    def name
      "LatLon.io"
    end

    def required_api_key_parts
      ["api_key"]
    end

    private # ---------------------------------------------------------------

    def base_query_url(query)
      "#{protocol}://latlon.io/api/v1/#{'reverse_' if query.reverse_geocode?}geocode?"
    end

    def results(query)
      return [] unless doc = fetch_data(query)
      if doc['error'].nil?
        [doc]
      # The API returned a 404 response, which indicates no results found
      elsif doc['error']['type'] == 'api_error'
        []
      elsif doc['error']['type'] == 'authentication_error'
        raise_error(Geocoder::InvalidApiKey) ||
          Geocoder.log(:warn, "LatLon.io service error: invalid API key.")
      else
        []
      end
    end

    def supported_protocols
      [:https]
    end

    private # ---------------------------------------------------------------

    def query_url_params(query)
      if query.reverse_geocode?
        {
          :token => configuration.api_key,
          :lat => query.coordinates[0],
          :lon => query.coordinates[1]
        }.merge(super)
      else
        {
          :token => configuration.api_key,
          :address => query.sanitized_text
        }.merge(super)
      end
    end

  end
end
