require 'geocoder/lookups/base'
require 'geocoder/results/ipstack'

module Geocoder::Lookup
  class Ipstack < Base

    ERROR_CODES = {
      404 => Geocoder::InvalidRequest,
      101 => Geocoder::InvalidApiKey,
      102 => Geocoder::Error,
      103 => Geocoder::InvalidRequest,
      104 => Geocoder::OverQueryLimitError,
      105 => Geocoder::RequestDenied,
      301 => Geocoder::InvalidRequest,
      302 => Geocoder::InvalidRequest,
      303 => Geocoder::RequestDenied,
    }
    ERROR_CODES.default = Geocoder::Error

    def name
      "Ipstack"
    end

    private # ----------------------------------------------------------------

    def base_query_url(query)
      "#{protocol}://#{host}/#{query.sanitized_text}?"
    end

    def query_url_params(query)
      {
        access_key: configuration.api_key
      }.merge(super)
    end

    def results(query)
      # don't look up a loopback or private address, just return the stored result
      return [reserved_result(query.text)] if query.internal_ip_address?

      return [] unless doc = fetch_data(query)

      if error = doc['error']
        code = error['code']
        msg = error['info']
        raise_error(ERROR_CODES[code], msg ) || Geocoder.log(:warn, "Ipstack Geocoding API error: #{msg}")
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

    def host
      configuration[:host] || "api.ipstack.com"
    end
  end
end
