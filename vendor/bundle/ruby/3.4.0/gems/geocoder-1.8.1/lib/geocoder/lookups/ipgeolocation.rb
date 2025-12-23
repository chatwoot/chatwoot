require 'geocoder/lookups/base'
require 'geocoder/results/ipgeolocation'


module Geocoder::Lookup
  class Ipgeolocation < Base

    ERROR_CODES = {
      400 => Geocoder::RequestDenied, # subscription is paused
      401 => Geocoder::InvalidApiKey, # missing/invalid API key
      403 => Geocoder::InvalidRequest, # invalid IP address
      404 => Geocoder::InvalidRequest, # not found
      423 => Geocoder::InvalidRequest # bogon/reserved IP address
    }
    ERROR_CODES.default = Geocoder::Error

    def name
      "Ipgeolocation"
    end

    def supported_protocols
      [:https]
    end

    private # ----------------------------------------------------------------

    def base_query_url(query)
      "#{protocol}://api.ipgeolocation.io/ipgeo?"
    end
    def query_url_params(query)
      {
          ip: query.sanitized_text,
          apiKey: configuration.api_key
      }.merge(super)
    end

    def results(query)
      # don't look up a loopback or private address, just return the stored result
      return [reserved_result(query.text)] if query.internal_ip_address?
      [fetch_data(query)]
    end

    def reserved_result(ip)
      {
          "ip"           => ip,
          "country_name" => "Reserved",
          "country_code2" => "RD"
      }
    end
  end
end
