require 'geocoder/lookups/base'
require 'geocoder/results/maxmind'
require 'csv'

module Geocoder::Lookup
  class Maxmind < Base

    def name
      "MaxMind"
    end

    private # ---------------------------------------------------------------

    def base_query_url(query)
      "#{protocol}://geoip.maxmind.com/#{service_code}?"
    end

    ##
    # Return the name of the configured service, or raise an exception.
    #
    def configured_service!
      if s = configuration[:service] and services.keys.include?(s)
        return s
      else
        raise(
          Geocoder::ConfigurationError,
          "When using MaxMind you MUST specify a service name: " +
          "Geocoder.configure(:maxmind => {:service => ...}), " +
          "where '...' is one of: #{services.keys.inspect}"
        )
      end
    end

    def service_code
      services[configured_service!]
    end

    def service_response_fields_count
      Geocoder::Result::Maxmind.field_names[configured_service!].size
    end

    def data_contains_error?(parsed_data)
      # if all fields given then there is an error
      parsed_data.size == service_response_fields_count and !parsed_data.last.nil?
    end

    ##
    # Service names mapped to code used in URL.
    #
    def services
      {
        :country => "a",
        :city => "b",
        :city_isp_org => "f",
        :omni => "e"
      }
    end

    def results(query)
      # don't look up a loopback or private address, just return the stored result
      return [reserved_result] if query.internal_ip_address?
      doc = fetch_data(query)
      if doc and doc.is_a?(Array)
        if !data_contains_error?(doc)
          return [doc]
        elsif doc.last == "INVALID_LICENSE_KEY"
          raise_error(Geocoder::InvalidApiKey) || Geocoder.log(:warn, "Invalid MaxMind API key.")
        end
      end
      return []
    end

    def parse_raw_data(raw_data)
      # Maxmind just returns text/plain as csv format but according to documentation,
      # we get ISO-8859-1 encoded string. We need to convert it.
      CSV.parse_line raw_data.force_encoding("ISO-8859-1").encode("UTF-8")
    end

    def reserved_result
      ",,,,0,0,0,0,,,".split(",")
    end

    def query_url_params(query)
      {
        :l => configuration.api_key,
        :i => query.sanitized_text
      }.merge(super)
    end
  end
end
