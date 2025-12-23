require 'geocoder/lookups/base'
require 'geocoder/results/postcodes_io'

module Geocoder::Lookup
  class PostcodesIo < Base
    def name
      'Postcodes.io'
    end

    def query_url(query)
      "#{protocol}://api.postcodes.io/postcodes/#{query.sanitized_text.gsub(/\s/, '')}"
    end

    def supported_protocols
      [:https]
    end

    private # ----------------------------------------------------------------

    def cache_key(query)
      query_url(query)
    end

    def results(query)
      response = fetch_data(query)
      return [] if response.nil? || response['status'] != 200 || response.empty?

      [response['result']]
    end
  end
end
