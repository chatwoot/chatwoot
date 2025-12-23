require 'geocoder/lookups/base'
require "geocoder/results/twogis"

module Geocoder::Lookup
  class Twogis < Base

    def name
      "2gis"
    end

    def required_api_key_parts
      ["key"]
    end

    def map_link_url(coordinates)
      "https://2gis.ru/?m=#{coordinates.join(',')}"
    end

    def supported_protocols
      [:https]
    end

    private # ---------------------------------------------------------------

    def base_query_url(query)
      "#{protocol}://catalog.api.2gis.com/3.0/items/geocode?"
    end

    def results(query)
      return [] unless doc = fetch_data(query)
      if doc['meta'] && doc['meta']['error']
        Geocoder.log(:warn, "2gis Geocoding API error: #{doc['meta']["code"]} (#{doc['meta']['error']["message"]}).")
        return []
      end
      if doc['result'] && doc = doc['result']['items']
        return doc.to_a
      else
        Geocoder.log(:warn, "2gis Geocoding API error: unexpected response format.")
        return []
      end
    end

    def query_url_params(query)
      if query.reverse_geocode?
        q = query.coordinates.reverse.join(",")
      else
        q = query.sanitized_text
      end
      params = {
        :q => q,
        :lang => "#{query.language || configuration.language}",
        :key => configuration.api_key,
        :fields => 'items.street,items.adm_div,items.full_address_name,items.point,items.geometry.centroid'
      }
      params.merge(super)
    end
  end
end
