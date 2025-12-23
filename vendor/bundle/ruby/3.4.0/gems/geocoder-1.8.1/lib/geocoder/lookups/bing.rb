require 'geocoder/lookups/base'
require "geocoder/results/bing"

module Geocoder::Lookup
  class Bing < Base

    def name
      "Bing"
    end

    def map_link_url(coordinates)
      "http://www.bing.com/maps/default.aspx?cp=#{coordinates.join('~')}"
    end

    def required_api_key_parts
      ["key"]
    end

    private # ---------------------------------------------------------------

    def base_query_url(query)
      text = CGI.escape(query.sanitized_text.strip)
      url = "#{protocol}://dev.virtualearth.net/REST/v1/Locations/"
      if query.reverse_geocode?
        url + "#{text}?"
      else
        if r = query.options[:region]
          url << "#{r}/"
        end
        # use the more forgiving 'unstructured' query format to allow special
        # chars, newlines, brackets, typos.
        url + "?q=#{text}&"
      end
    end

    def results(query)
      return [] unless doc = fetch_data(query)

      if doc['statusCode'] == 200
        return doc['resourceSets'].first['estimatedTotal'] > 0 ? doc['resourceSets'].first['resources'] : []
      elsif doc['statusCode'] == 401 and doc["authenticationResultCode"] == "InvalidCredentials"
        raise_error(Geocoder::InvalidApiKey) || Geocoder.log(:warn, "Invalid Bing API key.")
      elsif doc['statusCode'] == 403
        raise_error(Geocoder::RequestDenied) || Geocoder.log(:warn, "Bing Geocoding API error: Forbidden Request")
      elsif [500, 503].include?(doc['statusCode'])
        raise_error(Geocoder::ServiceUnavailable) ||
          Geocoder.log(:warn, "Bing Geocoding API error: Service Unavailable")
      else
        Geocoder.log(:warn, "Bing Geocoding API error: #{doc['statusCode']} (#{doc['statusDescription']}).")
      end
      return []
    end

    def query_url_params(query)
      {
        key: configuration.api_key,
        culture: (query.language || configuration.language)
      }.merge(super)
    end

    def check_response_for_errors!(response)
      super
      if server_overloaded?(response)
        raise_error(Geocoder::ServiceUnavailable) ||
          Geocoder.log(:warn, "Bing Geocoding API error: Service Unavailable")
      end
    end

    def valid_response?(response)
      super(response) and not server_overloaded?(response)
    end

    def server_overloaded?(response)
      # Occasionally, the servers processing service requests can be overloaded,
      # and you may receive some responses that contain no results for queries that
      # you would normally receive a result. To identify this situation,
      # check the HTTP headers of the response. If the HTTP header X-MS-BM-WS-INFO is set to 1,
      # it is best to wait a few seconds and try again.
      response['x-ms-bm-ws-info'].to_i == 1
    end
  end
end
