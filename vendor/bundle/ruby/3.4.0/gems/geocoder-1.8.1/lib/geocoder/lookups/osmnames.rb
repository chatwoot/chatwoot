require 'cgi'
require 'geocoder/lookups/base'
require 'geocoder/results/osmnames'

module Geocoder::Lookup
  class Osmnames < Base

    def name
      'OSM Names'
    end

    def required_api_key_parts
      configuration[:host] ? [] : ['key']
    end

    def supported_protocols
      [:https]
    end

    private

    def base_query_url(query)
      "#{base_url(query)}/#{params_url(query)}.js?"
    end

    def base_url(query)
      host = configuration[:host] || 'geocoder.tilehosting.com'
      "#{protocol}://#{host}"
    end

    def params_url(query)
      method, args = 'q', CGI.escape(query.sanitized_text)
      method, args = 'r', query.coordinates.join('/') if query.reverse_geocode?
      "#{country_limited(query)}#{method}/#{args}"
    end

    def results(query)
      return [] unless doc = fetch_data(query)
      if (error = doc['message'])
        raise_error(Geocoder::InvalidRequest, error) ||
          Geocoder.log(:warn, "OSMNames Geocoding API error: #{error}")
      else
        return doc['results']
      end
    end

    def query_url_params(query)
      {
        key: configuration.api_key
      }.merge(super)
    end

    def country_limited(query)
      "#{query.options[:country_code].downcase}/" if query.options[:country_code] && !query.reverse_geocode?
    end
  end
end
