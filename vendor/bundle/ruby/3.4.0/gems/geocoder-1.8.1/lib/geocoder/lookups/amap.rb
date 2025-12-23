require 'geocoder/lookups/base'
require "geocoder/results/amap"

module Geocoder::Lookup
  class Amap < Base

    def name
      "AMap"
    end

    def required_api_key_parts
      ["key"]
    end

    def supported_protocols
      [:http]
    end

    private # ---------------------------------------------------------------

    def base_query_url(query)
      path = query.reverse_geocode? ? 'regeo' : 'geo'
      "http://restapi.amap.com/v3/geocode/#{path}?"
    end

    def results(query, reverse = false)
      return [] unless doc = fetch_data(query)
      case [doc['status'], doc['info']]
      when ['1', 'OK']
        return doc['regeocodes'] unless doc['regeocodes'].blank?
        return [doc['regeocode']] unless doc['regeocode'].blank?
        return doc['geocodes'] unless doc['geocodes'].blank?
      when ['0', 'INVALID_USER_KEY']
        raise_error(Geocoder::InvalidApiKey, "invalid api key") ||
          Geocoder.log(:warn, "#{self.name} Geocoding API error: invalid api key.")
      else
        raise_error(Geocoder::Error, "server error.") ||
          Geocoder.log(:warn, "#{self.name} Geocoding API error: server error - [#{doc['info']}]")
      end
      return []
    end

    def query_url_params(query)
      params = {
        :key => configuration.api_key,
        :output => "json"
      }
      if query.reverse_geocode?
        params[:location] = revert_coordinates(query.text)
        params[:extensions] = "all"
        params[:coordsys] = "gps"
      else
        params[:address] = query.sanitized_text
      end
      params.merge(super)
    end

    def revert_coordinates(text)
      [text[1],text[0]].join(",")
    end

  end
end
