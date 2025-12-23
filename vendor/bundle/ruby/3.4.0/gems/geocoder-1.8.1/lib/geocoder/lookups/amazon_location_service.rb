require 'geocoder/lookups/base'
require 'geocoder/results/amazon_location_service'

module Geocoder::Lookup
  class AmazonLocationService < Base
    def results(query)
      params = query.options.dup

      # index_name is required
      # Aws::ParamValidator raises ArgumentError on missing required keys
      params.merge!(index_name: configuration[:index_name])

      # Aws::ParamValidator raises ArgumentError on unexpected keys
      params.delete(:lookup) 
      
      resp = if query.reverse_geocode?
        client.search_place_index_for_position(params.merge(position: query.coordinates.reverse))
      else
        client.search_place_index_for_text(params.merge(text: query.text))
      end
      
      resp.results.map(&:place)
    end

    private

    def client
      return @client if @client
      require_sdk
      keys = configuration.api_key
      if keys
        @client = Aws::LocationService::Client.new(
          access_key_id: keys[:access_key_id],
          secret_access_key: keys[:secret_access_key],
        )
      else
        @client = Aws::LocationService::Client.new
      end
    end

    def require_sdk
      begin
        require 'aws-sdk-locationservice'
      rescue LoadError
        raise_error(Geocoder::ConfigurationError) ||
          Geocoder.log(
            :error,
            "Couldn't load the Amazon Location Service SDK. " +
            "Install it with: gem install aws-sdk-locationservice -v '~> 1.4'"
          )
      end
    end
  end
end
