require 'geocoder/lookups/base'
require 'geocoder/results/postcode_anywhere_uk'

module Geocoder::Lookup
  class PostcodeAnywhereUk < Base
    # API documentation: http://www.postcodeanywhere.co.uk/Support/WebService/Geocoding/UK/Geocode/2/
    DAILY_LIMIT_EXEEDED_ERROR_CODES = ['8', '17'] # api docs say these two codes are the same error
    INVALID_API_KEY_ERROR_CODE = '2'

    def name
      'PostcodeAnywhereUk'
    end

    def required_api_key_parts
      %w(key)
    end

    private # ----------------------------------------------------------------

    def base_query_url(query)
      "#{protocol}://services.postcodeanywhere.co.uk/Geocoding/UK/Geocode/v2.00/json.ws?"
    end

    def results(query)
      response = fetch_data(query)
      return [] if response.nil? || !response.is_a?(Array) || response.empty?

      raise_exception_for_response(response[0]) if response[0]['Error']
      response
    end

    def raise_exception_for_response(response)
      case response['Error']
      when *DAILY_LIMIT_EXEEDED_ERROR_CODES
        raise_error(Geocoder::OverQueryLimitError, response['Cause']) || Geocoder.log(:warn, response['Cause'])
      when INVALID_API_KEY_ERROR_CODE
        raise_error(Geocoder::InvalidApiKey, response['Cause']) || Geocoder.log(:warn, response['Cause'])
      else # anything else just raise general error with the api cause
        raise_error(Geocoder::Error, response['Cause']) || Geocoder.log(:warn, response['Cause'])
      end
    end

    def query_url_params(query)
      {
        :location => query.sanitized_text,
        :key => configuration.api_key
      }.merge(super)
    end
  end
end
