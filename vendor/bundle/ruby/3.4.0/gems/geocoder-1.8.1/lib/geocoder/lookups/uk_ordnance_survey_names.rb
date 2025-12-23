require 'geocoder/lookups/base'
require 'geocoder/results/uk_ordnance_survey_names'

module Geocoder::Lookup
  class UkOrdnanceSurveyNames < Base

    def name
      'Ordance Survey Names'
    end

    def supported_protocols
      [:https]
    end

    def base_query_url(query)
      "#{protocol}://api.os.uk/search/names/v1/find?"
    end

    def required_api_key_parts
      ["key"]
    end

    def query_url(query)
      base_query_url(query) + url_query_string(query)
    end

    private # -------------------------------------------------------------

    def results(query)
      return [] unless doc = fetch_data(query)
      return [] if doc['header']['totalresults'].zero?
      return doc['results'].map { |r| r['GAZETTEER_ENTRY'] }
    end

    def query_url_params(query)
      {
        query: query.sanitized_text,
        key: configuration.api_key,
        fq: filter
      }.merge(super)
    end

    def local_types
      %w[
        City
        Hamlet
        Other_Settlement
        Town
        Village
        Postcode
      ]
    end

    def filter
      local_types.map { |t| "local_type:#{t}" }.join(' ')
    end

  end
end
