require 'geocoder/lookups/base'
require 'geocoder/results/ipregistry'

module Geocoder::Lookup
  class Ipregistry < Base

    ERROR_CODES = {
      400 => Geocoder::InvalidRequest,
      401 => Geocoder::InvalidRequest,
      402 => Geocoder::OverQueryLimitError,
      403 => Geocoder::InvalidApiKey,
      451 => Geocoder::RequestDenied,
      500 => Geocoder::Error
    }
    ERROR_CODES.default = Geocoder::Error

    def name
      "Ipregistry"
    end

    def supported_protocols
      [:https, :http]
    end

    private

    def base_query_url(query)
      "#{protocol}://#{host}/#{query.sanitized_text}?"
    end

    def cache_key(query)
      query_url(query)
    end

    def host
      configuration[:host] || "api.ipregistry.co"
    end

    def query_url_params(query)
      {
        key: configuration.api_key
      }.merge(super)
    end

    def results(query)
      # don't look up a loopback or private address, just return the stored result
      return [reserved_result(query.text)] if query.internal_ip_address?

      return [] unless (doc = fetch_data(query))

      if (error = doc['error'])
        code = error['code']
        msg = error['message']
        raise_error(ERROR_CODES[code], msg ) || Geocoder.log(:warn, "Ipregistry API error: #{msg}")
        return []
      end
      [doc]
    end

    def reserved_result(ip)
      {
        "ip"           => ip,
        "country_name" => "Reserved",
        "country_code" => "RD"
      }
    end
  end
end
