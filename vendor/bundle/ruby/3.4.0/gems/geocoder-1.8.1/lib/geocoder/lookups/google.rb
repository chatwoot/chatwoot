require 'geocoder/lookups/base'
require "geocoder/results/google"

module Geocoder::Lookup
  class Google < Base

    def name
      "Google"
    end

    def map_link_url(coordinates)
      "http://maps.google.com/maps?q=#{coordinates.join(',')}"
    end

    def supported_protocols
      # Google requires HTTPS if an API key is used.
      if configuration.api_key
        [:https]
      else
        [:http, :https]
      end
    end

    private # ---------------------------------------------------------------

    def base_query_url(query)
      "#{protocol}://maps.googleapis.com/maps/api/geocode/json?"
    end

    def configure_ssl!(client)
      client.instance_eval {
        @ssl_context = OpenSSL::SSL::SSLContext.new
        options = OpenSSL::SSL::OP_NO_SSLv2 | OpenSSL::SSL::OP_NO_SSLv3
        if OpenSSL::SSL.const_defined?('OP_NO_COMPRESSION')
          options |= OpenSSL::SSL::OP_NO_COMPRESSION
        end
        @ssl_context.set_params({options: options})
      }
    end

    def valid_response?(response)
      json = parse_json(response.body)
      status = json["status"] if json
      super(response) and ['OK', 'ZERO_RESULTS'].include?(status)
    end

    def result_root_attr
      'results'
    end

    def results(query)
      return [] unless doc = fetch_data(query)
      case doc['status']
      when "OK" # OK status implies >0 results
        return doc[result_root_attr]
      when "OVER_QUERY_LIMIT"
        raise_error(Geocoder::OverQueryLimitError) ||
          Geocoder.log(:warn, "#{name} API error: over query limit.")
      when "REQUEST_DENIED"
        raise_error(Geocoder::RequestDenied, doc['error_message']) ||
          Geocoder.log(:warn, "#{name} API error: request denied (#{doc['error_message']}).")
      when "INVALID_REQUEST"
        raise_error(Geocoder::InvalidRequest, doc['error_message']) ||
          Geocoder.log(:warn, "#{name} API error: invalid request (#{doc['error_message']}).")
      end
      return []
    end

    def query_url_google_params(query)
      params = {
        :sensor => "false",
        :language => (query.language || configuration.language)
      }
      if query.options[:google_place_id]
        params[:place_id] = query.sanitized_text
      else
        params[(query.reverse_geocode? ? :latlng : :address)] = query.sanitized_text
      end
      unless (bounds = query.options[:bounds]).nil?
        params[:bounds] = bounds.map{ |point| "%f,%f" % point }.join('|')
      end
      unless (region = query.options[:region]).nil?
        params[:region] = region
      end
      unless (components = query.options[:components]).nil?
        params[:components] = components.is_a?(Array) ? components.join("|") : components
      end
      unless (result_type = query.options[:result_type]).nil?
        params[:result_type] = result_type.is_a?(Array) ? result_type.join("|") : result_type
      end
      params
    end

    def query_url_params(query)
      query_url_google_params(query).merge(
        :key => configuration.api_key
      ).merge(super)
    end
  end
end
