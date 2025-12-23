require 'geocoder/lookups/base'
require 'geocoder/results/here'

module Geocoder::Lookup
  class Here < Base

    def name
      "Here"
    end

    def required_api_key_parts
      ['api_key']
    end

    def supported_protocols
      [:https]
    end

    private # ---------------------------------------------------------------

    def base_query_url(query)
      service = query.reverse_geocode? ? "revgeocode" : "geocode"

      "#{protocol}://#{service}.search.hereapi.com/v1/#{service}?"
    end

    def results(query)
      unless configuration.api_key.is_a?(String)
        api_key_not_string!
        return []
      end
      return [] unless doc = fetch_data(query)
      return [] if doc["items"].nil?

      doc["items"]
    end

    def query_url_here_options(query, reverse_geocode)
      options = {
        apiKey: configuration.api_key,
        lang: (query.language || configuration.language)
      }
      return options if reverse_geocode

      unless (country = query.options[:country]).nil?
        options[:in] = "countryCode:#{country}"
      end

      options
    end

    def query_url_params(query)
      if query.reverse_geocode?
        super.merge(query_url_here_options(query, true)).merge(
          at: query.sanitized_text
        )
      else
        super.merge(query_url_here_options(query, false)).merge(
          q: query.sanitized_text
        )
      end
    end

    def api_key_not_string!
      msg = <<~MSG
        API key for HERE Geocoding and Search API should be a string.
        For more info on how to obtain it, please see https://developer.here.com/documentation/identity-access-management/dev_guide/topics/plat-using-apikeys.html
      MSG

      raise_error(Geocoder::ConfigurationError, msg) || Geocoder.log(:warn, msg)
    end
  end
end
