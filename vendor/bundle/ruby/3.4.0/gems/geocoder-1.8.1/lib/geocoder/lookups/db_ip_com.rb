require 'geocoder/lookups/base'
require 'geocoder/results/db_ip_com'

module Geocoder::Lookup
  class DbIpCom < Base

    def name
      'DB-IP.com'
    end

    def supported_protocols
      [:https, :http]
    end

    def required_api_key_parts
      ['api_key']
    end

    private # ----------------------------------------------------------------

    def base_query_url(query)
      "#{protocol}://api.db-ip.com/v2/#{configuration.api_key}/#{query.sanitized_text}?"
    end

    ##
    # Same as query_url but without the api key.
    #
    def cache_key(query)
      "#{protocol}://api.db-ip.com/v2/#{query.sanitized_text}?" + hash_to_query(cache_key_params(query))
    end

    def results(query)
      return [] unless (doc = fetch_data(query))

      case doc['error']
      when 'maximum number of queries per day exceeded'
        raise_error Geocoder::OverQueryLimitError ||
                    Geocoder.log(:warn, 'DB-API query limit exceeded.')

      when 'invalid API key'
        raise_error Geocoder::InvalidApiKey ||
                    Geocoder.log(:warn, 'Invalid DB-IP API key.')
      when nil
        [doc]

      else
        raise_error Geocoder::Error ||
                    Geocoder.log(:warn, "Request failed: #{doc['error']}")
      end
    end
  end
end
