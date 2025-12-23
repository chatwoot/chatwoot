require 'geocoder/lookups/base'
require 'geocoder/results/opencagedata'

module Geocoder::Lookup
  class Opencagedata < Base

    def name
      "OpenCageData"
    end

    def required_api_key_parts
      ["key"]
    end

    private # ----------------------------------------------------------------

    def base_query_url(query)
      "#{protocol}://api.opencagedata.com/geocode/v1/json?"
    end

    def results(query)
      return [] unless doc = fetch_data(query)
      # return doc["results"]

      messages = doc['status']['message']
      case doc['status']['code']
      when 400 # Error with input
        raise_error(Geocoder::InvalidRequest, messages) ||
          Geocoder.log(:warn, "Opencagedata Geocoding API error: #{messages}")
      when 403 # Key related error
        raise_error(Geocoder::InvalidApiKey, messages) ||
          Geocoder.log(:warn, "Opencagedata Geocoding API error: #{messages}")
      when 402 # Quata Exceeded
          raise_error(Geocoder::OverQueryLimitError, messages) ||
          Geocoder.log(:warn, "Opencagedata Geocoding API error: #{messages}")
      when 500 # Unknown error
        raise_error(Geocoder::Error, messages) ||
          Geocoder.log(:warn, "Opencagedata Geocoding API error: #{messages}")
      end

      return doc["results"]
    end

    def query_url_params(query)
      params = {
        :q => query.sanitized_text,
        :key => configuration.api_key,
        :language => (query.language || configuration.language)
      }.merge(super)

      [:abbrv, :countrycode, :min_confidence, :no_dedupe, :no_annotations, :no_record, :limit].each do |option|
        unless (option_value = query.options[option]).nil?
          params[option] = option_value
        end
      end

      unless (bounds = query.options[:bounds]).nil?
        params[:bounds] = bounds.map{ |point| "%f,%f" % point }.join(',')
      end

      params
    end

  end
end
