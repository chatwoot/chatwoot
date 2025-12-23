# encoding: utf-8

require 'geocoder/lookups/base'
require 'geocoder/results/ipqualityscore'

module Geocoder::Lookup
  class Ipqualityscore < Base

    def name
      "IPQualityScore"
    end

    def required_api_key_parts
      ['api_key']
    end

    private # ---------------------------------------------------------------

    def base_query_url(query)
      "#{protocol}://ipqualityscore.com/api/json/ip/#{configuration.api_key}/#{query.sanitized_text}?"
    end

    def valid_response?(response)
      if (json = parse_json(response.body))
        success = json['success']
      end
      super && success == true
    end

    def results(query, reverse = false)
      return [] unless doc = fetch_data(query)

      return [doc] if doc['success']

      case doc['message']
      when /invalid (.*) key/i
        raise_error Geocoder::InvalidApiKey ||
                    Geocoder.log(:warn, "#{name} API error: invalid api key.")
      when /insufficient credits/, /exceeded your request quota/
        raise_error Geocoder::OverQueryLimitError ||
                    Geocoder.log(:warn, "#{name} API error: query limit exceeded.")
      when /invalid (.*) address/i
        raise_error Geocoder::InvalidRequest ||
                    Geocoder.log(:warn, "#{name} API error: invalid request.")
      end

      [doc]
    end
  end
end
