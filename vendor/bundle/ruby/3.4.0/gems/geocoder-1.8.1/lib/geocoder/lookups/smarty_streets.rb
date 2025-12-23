require 'geocoder/lookups/base'
require 'geocoder/results/smarty_streets'

module Geocoder::Lookup
  class SmartyStreets < Base
    def name
      "SmartyStreets"
    end

    def required_api_key_parts
      %w(auth-id auth-token)
    end

    # required by API as of 26 March 2015
    def supported_protocols
      [:https]
    end

    private # ---------------------------------------------------------------

    def base_query_url(query)
      if international?(query)
        "#{protocol}://international-street.api.smartystreets.com/verify?"
      elsif zipcode_only?(query)
        "#{protocol}://us-zipcode.api.smartystreets.com/lookup?"
      else
        "#{protocol}://us-street.api.smartystreets.com/street-address?"
      end
    end

    def zipcode_only?(query)
      !query.text.is_a?(Array) and query.to_s.strip =~ /\A\d{5}(-\d{4})?\Z/
    end

    def international?(query)
      !query.options[:country].nil?
    end

    def query_url_params(query)
      params = {}
      if international?(query)
        params[:freeform] = query.sanitized_text
        params[:country] = query.options[:country]
        params[:geocode] = true
      elsif zipcode_only?(query)
        params[:zipcode] = query.sanitized_text
      else
        params[:street] = query.sanitized_text
      end
      if configuration.api_key.is_a?(Array)
        params[:"auth-id"] = configuration.api_key[0]
        params[:"auth-token"] = configuration.api_key[1]
      else
        params[:"auth-token"] = configuration.api_key
      end
      params.merge(super)
    end

    def results(query)
      doc = fetch_data(query) || []
      if doc.is_a?(Hash) and doc.key?('status') # implies there's an error
        return []
      else
        return doc
      end
    end
  end
end
