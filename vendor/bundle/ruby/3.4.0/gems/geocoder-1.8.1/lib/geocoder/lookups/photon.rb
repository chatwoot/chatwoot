require 'geocoder/lookups/base'
require 'geocoder/results/photon'

module Geocoder::Lookup
  class Photon < Base
    def name
      'Photon'
    end

    private # ---------------------------------------------------------------

    def supported_protocols
      [:https]
    end

    def base_query_url(query)
      host = configuration[:host] || 'photon.komoot.io'
      method = query.reverse_geocode? ? 'reverse' : 'api'
      "#{protocol}://#{host}/#{method}?"
    end

    def results(query)
      return [] unless (doc = fetch_data(query))
      return [] unless doc['type'] == 'FeatureCollection'
      return [] unless doc['features'] || doc['features'].present?

      doc['features']
    end

    def query_url_params(query)
      lang = query.language || configuration.language
      params = { lang: lang, limit: query.options[:limit] }

      if query.reverse_geocode?
        params.merge!(query_url_params_reverse(query))
      else
        params.merge!(query_url_params_coordinates(query))
      end

      params.merge!(super)
    end

    def query_url_params_coordinates(query)
      params = { q: query.sanitized_text }

      if (bias = query.options[:bias])
        params.merge!(lat: bias[:latitude], lon: bias[:longitude], location_bias_scale: bias[:scale])
      end

      if (filter = query_url_params_coordinates_filter(query))
        params.merge!(filter)
      end

      params
    end

    def query_url_params_coordinates_filter(query)
      filter = query.options[:filter]
      return unless filter

      bbox = filter[:bbox]
      {
        bbox: bbox.is_a?(Array) ? bbox.join(',') : bbox,
        osm_tag: filter[:osm_tag]
      }
    end

    def query_url_params_reverse(query)
      params = { lat: query.coordinates[0], lon: query.coordinates[1], radius: query.options[:radius] }

      if (dsort = query.options[:distance_sort])
        params[:distance_sort] = dsort ? 'true' : 'false'
      end

      if (filter = query_url_params_reverse_filter(query))
        params.merge!(filter)
      end

      params
    end

    def query_url_params_reverse_filter(query)
      filter = query.options[:filter]
      return unless filter

      { query_string_filter: filter[:string] }
    end
  end
end
