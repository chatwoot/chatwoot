require 'geocoder/lookups/base'
require "geocoder/results/nominatim"

module Geocoder::Lookup
  class Nominatim < Base

    def name
      "Nominatim"
    end

    def map_link_url(coordinates)
      "https://www.openstreetmap.org/?lat=#{coordinates[0]}&lon=#{coordinates[1]}&zoom=15&layers=M"
    end

    private # ---------------------------------------------------------------

    def base_query_url(query)
      method = query.reverse_geocode? ? "reverse" : "search"
      "#{protocol}://#{configured_host}/#{method}?"
    end

    def configured_host
      configuration[:host] || "nominatim.openstreetmap.org"
    end

    def use_ssl?
      # nominatim.openstreetmap.org redirects HTTP requests to HTTPS
      if configured_host == "nominatim.openstreetmap.org"
        true
      else
        super
      end
    end

    def results(query)
      return [] unless doc = fetch_data(query)
      doc.is_a?(Array) ? doc : [doc]
    end

    def parse_raw_data(raw_data)
      if raw_data.include?("Bandwidth limit exceeded")
        raise_error(Geocoder::OverQueryLimitError) || Geocoder.log(:warn, "Over API query limit.")
      else
        super(raw_data)
      end
    end

    def query_url_params(query)
      params = {
        :format => "json",
        :addressdetails => "1",
        :"accept-language" => (query.language || configuration.language)
      }.merge(super)
      if query.reverse_geocode?
        lat,lon = query.coordinates
        params[:lat] = lat
        params[:lon] = lon
      else
        params[:q] = query.sanitized_text
      end
      params
    end
  end
end
