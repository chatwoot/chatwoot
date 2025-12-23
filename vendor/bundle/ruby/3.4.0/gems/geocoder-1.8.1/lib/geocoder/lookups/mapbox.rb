require 'geocoder/lookups/base'
require "geocoder/results/mapbox"

module Geocoder::Lookup
  class Mapbox < Base

    def name
      "Mapbox"
    end

    private # ---------------------------------------------------------------

    def base_query_url(query)
      "#{protocol}://api.mapbox.com/geocoding/v5/#{dataset}/#{mapbox_search_term(query)}.json?"
    end

    def results(query)
      return [] unless data = fetch_data(query)
      if data['features']
        sort_relevant_feature(data['features'])
      elsif data['message'] =~ /Invalid\sToken/
        raise_error(Geocoder::InvalidApiKey, data['message'])
      else
        []
      end
    end

    def query_url_params(query)
      {access_token: configuration.api_key}.merge(super(query))
    end

    def mapbox_search_term(query)
      require 'cgi' unless defined?(CGI) && defined?(CGI.escape)
      if query.reverse_geocode?
        lat,lon = query.coordinates
        "#{CGI.escape lon},#{CGI.escape lat}"
      else
        # truncate at first semicolon so Mapbox doesn't go into batch mode
        # (see Github issue #1299)
        CGI.escape query.text.to_s.split(';').first.to_s
      end
    end

    def dataset
      configuration[:dataset] || "mapbox.places"
    end

    def supported_protocols
      [:https]
    end

    def sort_relevant_feature(features)
      # Sort by descending relevance; Favor original order for equal relevance (eg occurs for reverse geocoding)
      features.sort_by do |feature|
        [feature["relevance"],-features.index(feature)]
      end.reverse
    end
  end
end
