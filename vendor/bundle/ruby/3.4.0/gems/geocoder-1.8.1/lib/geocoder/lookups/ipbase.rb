require 'geocoder/lookups/base'
require 'geocoder/results/ipbase'

module Geocoder::Lookup
  class Ipbase < Base

    def name
      "ipbase.com"
    end

    def supported_protocols
      [:https]
    end

    private # ---------------------------------------------------------------

    def base_query_url(query)
      "https://api.ipbase.com/v2/info?"
    end

    def query_url_params(query)
      {
        :ip => query.sanitized_text,
        :apikey => configuration.api_key
      }
    end

    def results(query)
      # don't look up a loopback or private address, just return the stored result
      return [reserved_result(query.text)] if query.internal_ip_address?
      doc = fetch_data(query) || {}
      doc.fetch("data", {})["location"] ? [doc] : []
    end

    def reserved_result(ip)
      {
        "data" => {
          "ip" => ip,
          "location" => {
            "city" => { "name" => "" },
            "country" => { "alpha2" => "RD", "name" => "Reserved" },
            "region" => { "alpha2" => "", "name" => "" },
            "zip" => ""
          }
        }
      }
    end
  end
end
