require 'geocoder/lookups/base'
require "geocoder/results/nationaal_georegister_nl"

module Geocoder::Lookup
  class NationaalGeoregisterNl < Base

    def name
      'Nationaal Georegister Nederland'
    end

    private # ---------------------------------------------------------------

    def cache_key(query)
      base_query_url(query) + hash_to_query(query_url_params(query))
    end

    def base_query_url(query)
      "#{protocol}://geodata.nationaalgeoregister.nl/locatieserver/v3/free?"
    end

    def valid_response?(response)
      json   = parse_json(response.body)
      super(response) if json
    end

    def results(query)
      return [] unless doc = fetch_data(query)
      return doc['response']['docs']
    end

    def query_url_params(query)
      {
        fl: '*',
        q:  query.text
      }.merge(super)
    end
  end
end
