require 'geocoder/lookups/base'
require "geocoder/results/melissa_street"

module Geocoder::Lookup
  class MelissaStreet < Base

    def name
      "MelissaStreet"
    end

    def results(query)
      return [] unless doc = fetch_data(query)

      if doc["TransmissionResults"] == "GE05"
        raise_error(Geocoder::InvalidApiKey) ||
          Geocoder.log(:warn, "Melissa service error: invalid API key.")
      end

      return doc["Records"]
    end

    private # ---------------------------------------------------------------

    def base_query_url(query)
      "#{protocol}://address.melissadata.net/v3/WEB/GlobalAddress/doGlobalAddress?"
    end

    def query_url_params(query)
      params = {
        id: configuration.api_key,
        format: "JSON",
        a1: query.sanitized_text,
        loc: query.options[:city],
        admarea: query.options[:state],
        postal: query.options[:postal],
        ctry: query.options[:country]
      }
      params.merge(super)
    end
  end
end
