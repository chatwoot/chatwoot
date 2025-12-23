require 'geocoder/lookups/base'
require 'geocoder/results/ipapi_com'

module Geocoder::Lookup
  class IpapiCom < Base

    def name
      "ip-api.com"
    end

    def supported_protocols
      if configuration.api_key
        [:http, :https]
      else
        [:http]
      end
    end

    private # ----------------------------------------------------------------

    def base_query_url(query)
      domain = configuration.api_key ? "pro.ip-api.com" : "ip-api.com"
      url = "#{protocol}://#{domain}/json/#{query.sanitized_text}"
      url << "?" if not url_query_string(query).empty?
      url
    end

    def parse_raw_data(raw_data)
      if raw_data.chomp == "invalid key"
        invalid_key_result
      else
        super(raw_data)
      end
    end

    def results(query)
      # don't look up a loopback or private address, just return the stored result
      return [reserved_result(query.text)] if query.internal_ip_address?

      return [] unless doc = fetch_data(query)

      if doc["message"] == "invalid key"
        raise_error(Geocoder::InvalidApiKey) || Geocoder.log(:warn, "Invalid API key.")
        return []
      else
        return [doc]
      end
    end

    def reserved_result(query)
      {
        "message"      => "reserved range",
        "query"        => query,
        "status"       => "fail",
        "ip"           => query,
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

    def invalid_key_result
      {
        "message"      => "invalid key"
      }
    end

    def query_url_params(query)
      params = {}
      params.merge!(fields: configuration[:fields]) if configuration.has_key?(:fields)
      params.merge!(key: configuration.api_key) if configuration.api_key
      params.merge(super)
    end

  end
end
