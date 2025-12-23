module RestClient

  # A Response from RestClient, you can access the response body, the code or the headers.
  #
  class Response < String

    include AbstractResponse

    # Return the HTTP response body.
    #
    # Future versions of RestClient will deprecate treating response objects
    # directly as strings, so it will be necessary to call `.body`.
    #
    # @return [String]
    #
    def body
      # Benchmarking suggests that "#{self}" is fastest, and that caching the
      # body string in an instance variable doesn't make it enough faster to be
      # worth the extra memory storage.
      String.new(self)
    end

    # Convert the HTTP response body to a pure String object.
    #
    # @return [String]
    def to_s
      body
    end

    # Convert the HTTP response body to a pure String object.
    #
    # @return [String]
    def to_str
      body
    end

    def inspect
      "<RestClient::Response #{code.inspect} #{body_truncated(10).inspect}>"
    end

    # Initialize a Response object. Because RestClient::Response is
    # (unfortunately) a subclass of String for historical reasons,
    # Response.create is the preferred initializer.
    #
    # @param [String, nil] body The response body from the Net::HTTPResponse
    # @param [Net::HTTPResponse] net_http_res
    # @param [RestClient::Request] request
    # @param [Time] start_time
    def self.create(body, net_http_res, request, start_time=nil)
      result = self.new(body || '')

      result.response_set_vars(net_http_res, request, start_time)
      fix_encoding(result)

      result
    end

    # Set the String encoding according to the 'Content-Type: charset' header,
    # if possible.
    def self.fix_encoding(response)
      charset = RestClient::Utils.get_encoding_from_headers(response.headers)
      encoding = nil

      begin
        encoding = Encoding.find(charset) if charset
      rescue ArgumentError
        if response.log
          response.log << "No such encoding: #{charset.inspect}"
        end
      end

      return unless encoding

      response.force_encoding(encoding)

      response
    end

    private

    def body_truncated(length)
      b = body
      if b.length > length
        b[0..length] + '...'
      else
        b
      end
    end
  end
end
