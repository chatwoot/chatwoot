require 'geocoder/lookups/base'
require "geocoder/results/yandex"

module Geocoder::Lookup
  class Yandex < Base

    def name
      "Yandex"
    end

    def map_link_url(coordinates)
      "http://maps.yandex.ru/?ll=#{coordinates.reverse.join(',')}"
    end

    def supported_protocols
      [:https]
    end

    private # ---------------------------------------------------------------

    def base_query_url(query)
      "#{protocol}://geocode-maps.yandex.ru/1.x/?"
    end

    def results(query)
      return [] unless doc = fetch_data(query)
      if [400, 403].include? doc['statusCode']
        if doc['statusCode'] == 403 and doc['message'] == 'Invalid key'
          raise_error(Geocoder::InvalidApiKey) || Geocoder.log(:warn, "Invalid API key.")
        else
          Geocoder.log(:warn, "Yandex Geocoding API error: #{doc['statusCode']} (#{doc['message']}).")
        end
        return []
      end
      if doc = doc['response']['GeoObjectCollection']
        return doc['featureMember'].to_a
      else
        Geocoder.log(:warn, "Yandex Geocoding API error: unexpected response format.")
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
        :geocode => q,
        :format => "json",
        :lang => "#{query.language || configuration.language}", # supports ru, uk, be, default -> ru
        :apikey => configuration.api_key
      }
      unless (bounds = query.options[:bounds]).nil?
        params[:bbox] = bounds.map{ |point| "%f,%f" % point }.join('~')
      end
      params.merge(super)
    end
  end
end
