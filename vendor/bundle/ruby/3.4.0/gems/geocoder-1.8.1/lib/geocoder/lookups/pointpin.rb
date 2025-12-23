require 'geocoder/lookups/base'
require 'geocoder/results/pointpin'

module Geocoder::Lookup
  class Pointpin < Base

    def name
      "Pointpin"
    end

    def required_api_key_parts
      ["key"]
    end

    def query_url(query)
      "#{protocol}://geo.pointp.in/#{configuration.api_key}/json/#{query.sanitized_text}"
    end

    private # ----------------------------------------------------------------

    def cache_key(query)
      "#{protocol}://geo.pointp.in/json/#{query.sanitized_text}"
    end

    def results(query)
      # don't look up a loopback or private address, just return the stored result
      return [] if query.internal_ip_address?
      doc = fetch_data(query)
      if doc and doc.is_a?(Hash)
        if !data_contains_error?(doc)
          return [doc]
        elsif doc['error']
          case doc['error']
          when "Invalid IP address"
            raise_error(Geocoder::InvalidRequest) || Geocoder.log(:warn, "Invalid Pointpin request.")
          when "Invalid API key"
            raise_error(Geocoder::InvalidApiKey) || Geocoder.log(:warn, "Invalid Pointpin API key.")
          when "Address not found"
            Geocoder.log(:warn, "Address not found.")
          end
        else
          raise_error(Geocoder::Error) || Geocoder.log(:warn, "Pointpin server error")
        end
      end

      return []
    end

    def data_contains_error?(parsed_data)
      parsed_data.keys.include?('error')
    end

    # TODO: replace this hash with what's actually returned by Pointpin
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
  end
end
