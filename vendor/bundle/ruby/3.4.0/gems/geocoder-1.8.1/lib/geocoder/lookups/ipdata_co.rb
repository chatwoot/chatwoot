require 'geocoder/lookups/base'
require 'geocoder/results/ipdata_co'

module Geocoder::Lookup
  class IpdataCo < Base

    def name
      "ipdata.co"
    end

    def supported_protocols
      [:https]
    end

    def query_url(query)
      # Ipdata.co requires that the API key be sent as a query parameter.
      # It no longer supports API keys sent as headers.
      "#{protocol}://#{host}/#{query.sanitized_text}?api-key=#{configuration.api_key}"
    end

    private # ---------------------------------------------------------------

    def cache_key(query)
      query_url(query)
    end

    def results(query)
      # don't look up a loopback or private address, just return the stored result
      return [reserved_result(query.text)] if query.internal_ip_address?
      # note: Ipdata.co returns plain text on bad request
      (doc = fetch_data(query)) ? [doc] : []
    end

    def reserved_result(ip)
      {
        "ip"           => ip,
        "city"         => "",
        "region_code"  => "",
        "region_name"  => "",
        "metrocode"    => "",
        "zipcode"      => "",
        "latitude"     => "0",
        "longitude"    => "0",
        "country_name" => "Reserved",
        "country_code" => "RD"
      }
    end

    def host
      configuration[:host] || "api.ipdata.co"
    end

    def check_response_for_errors!(response)
      if response.code.to_i == 403
        raise_error(Geocoder::RequestDenied) ||
          Geocoder.log(:warn, "Geocoding API error: 403 API key does not exist")
      else
        super(response)
      end
    end
  end
end
