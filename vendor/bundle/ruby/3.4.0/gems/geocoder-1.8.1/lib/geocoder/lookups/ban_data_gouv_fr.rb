# encoding: utf-8

require 'geocoder/lookups/base'
require 'geocoder/results/ban_data_gouv_fr'

module Geocoder::Lookup
  class BanDataGouvFr < Base

    def name
      "Base Adresse Nationale Française"
    end

    def map_link_url(coordinates)
      "https://www.openstreetmap.org/#map=19/#{coordinates.join('/')}"
    end

    private # ---------------------------------------------------------------

    def base_query_url(query)
      method = query.reverse_geocode? ? "reverse" : "search"
      "#{protocol}://api-adresse.data.gouv.fr/#{method}/?"
    end

    def any_result?(doc)
      doc['features'] and doc['features'].any?
    end

    def results(query)
      if doc = fetch_data(query) and any_result?(doc)
        [doc]
      else
        []
      end
    end

    #### PARAMS ####

    def query_url_params(query)
      query_ban_datagouv_fr_params(query).merge(super)
    end

    def query_ban_datagouv_fr_params(query)
      query.reverse_geocode? ? reverse_geocode_ban_fr_params(query) : search_geocode_ban_fr_params(query)
    end

    #### SEARCH GEOCODING PARAMS ####
    #
    #  :q             =>    required, full text search param)

    #  :limit         =>    force limit number of results returned by raw API
    #                       (default = 5) note : only first result is taken
    #                       in account in geocoder
    #
    #  :autocomplete  =>    pass 0 to disable autocomplete treatment of :q
    #                       (default = 1)
    #
    #  :lat           =>    force filter results around specific lat/lon
    #
    #  :lon           =>    force filter results around specific lat/lon
    #
    #  :type          =>    force filter the returned result type
    #                       (check results for a list of accepted types)
    #
    #  :postcode      =>    force filter results on a specific city post code
    #
    #  :citycode      =>    force filter results on a specific city UUID INSEE code
    #
    #  For up to date doc (in french only) : https://adresse.data.gouv.fr/api/
    #
    def search_geocode_ban_fr_params(query)
      params = {
        q: query.sanitized_text
      }
      unless (limit = query.options[:limit]).nil? || !limit_param_is_valid?(limit)
        params[:limit] = limit.to_i
      end
      unless (autocomplete = query.options[:autocomplete]).nil? || !autocomplete_param_is_valid?(autocomplete)
        params[:autocomplete] = autocomplete.to_s
      end
      unless (type = query.options[:type]).nil? || !type_param_is_valid?(type)
        params[:type] = type.downcase
      end
      unless (postcode = query.options[:postcode]).nil? || !code_param_is_valid?(postcode)
        params[:postcode] = postcode.to_s
      end
      unless (citycode = query.options[:citycode]).nil? || !code_param_is_valid?(citycode)
        params[:citycode] = citycode.to_s
      end
      unless (lat = query.options[:lat]).nil? || !latitude_is_valid?(lat)
        params[:lat] = lat
      end
      unless (lon = query.options[:lon]).nil? || !longitude_is_valid?(lon)
        params[:lon] = lon
      end
      params
    end

    #### REVERSE GEOCODING PARAMS ####
    #
    #  :lat           =>    required
    #
    #  :lon           =>    required
    #
    #  :type          =>    force returned results type
    #                       (check results for a list of accepted types)
    #
    def reverse_geocode_ban_fr_params(query)
      lat_lon = query.coordinates
      params = {
          lat: lat_lon.first,
          lon: lat_lon.last
      }
      unless (type = query.options[:type]).nil? || !type_param_is_valid?(type)
        params[:type] = type.downcase
      end
      params
    end

    def limit_param_is_valid?(param)
      param.to_i.positive?
    end

    def autocomplete_param_is_valid?(param)
      [0,1].include?(param.to_i)
    end

    def type_param_is_valid?(param)
      %w(housenumber street locality village town city).include?(param.downcase)
    end

    def code_param_is_valid?(param)
      (1..99999).include?(param.to_i)
    end

    def latitude_is_valid?(param)
      param.to_f <= 90 && param.to_f >= -90
    end

    def longitude_is_valid?(param)
      param.to_f <= 180 && param.to_f >= -180
    end
  end
end
