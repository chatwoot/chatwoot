# encoding: utf-8

require 'geocoder/lookups/base'
require 'geocoder/results/abstract_api'

module Geocoder::Lookup
  class AbstractApi < Base

    def name
      "Abstract API"
    end

    def required_api_key_parts
      ['api_key']
    end

    def supported_protocols
      [:https]
    end

    private # ---------------------------------------------------------------

    def base_query_url(query)
      "#{protocol}://ipgeolocation.abstractapi.com/v1/?"
    end

    def query_url_params(query)
      params = {api_key: configuration.api_key}

      ip_address = query.sanitized_text
      if ip_address.is_a?(String) && ip_address.length > 0
        params[:ip_address] = ip_address
      end

      params.merge(super)
    end

    def results(query, reverse = false)
      if doc = fetch_data(query)
        [doc]
      else
        []
      end
    end
  end
end
