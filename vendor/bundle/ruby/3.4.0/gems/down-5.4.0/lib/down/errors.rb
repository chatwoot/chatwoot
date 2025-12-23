# frozen-string-literal: true

module Down
  # generic error which is a superclass to all other errors
  class Error < StandardError; end

  # raised when the file is larger than the specified maximum size
  class TooLarge < Error; end

  # raised when the given URL couldn't be parsed
  class InvalidUrl < Error; end

  # raised when the number of redirects was larger than the specified maximum
  class TooManyRedirects < Error; end

  # raised when the requested resource has not been modified
  class NotModified < Error; end

  # raised when response returned 4xx or 5xx response
  class ResponseError < Error
    attr_reader :response

    def initialize(message, response = nil)
      super(message)
      @response = response
    end
  end

  # raised when response returned 4xx response
  class ClientError < ResponseError; end

  # raised when response returned 404 response
  class NotFound < ClientError; end

  # raised when response returned 5xx response
  class ServerError < ResponseError; end

  # raised when there was an error connecting to the server
  class ConnectionError < Error; end

  # raised when connecting to the server too longer than the specified timeout
  class TimeoutError < ConnectionError; end

  # raised when an SSL error was raised
  class SSLError < Error; end
end
