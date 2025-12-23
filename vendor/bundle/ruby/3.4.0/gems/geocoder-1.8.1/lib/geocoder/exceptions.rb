require 'timeout'

module Geocoder

  class Error < StandardError
  end

  class ConfigurationError < Error
  end

  class OverQueryLimitError < Error
  end

  class ResponseParseError < Error
    attr_reader :response

    def initialize(response)
      @response = response
    end
  end

  class RequestDenied < Error
  end

  class InvalidRequest < Error
  end

  class InvalidApiKey < Error
  end

  class ServiceUnavailable < Error
  end

  class LookupTimeout < ::Timeout::Error
  end

  class NetworkError < Error
  end

end
