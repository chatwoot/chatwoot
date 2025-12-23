# frozen_string_literal: true

module Rack

  # A Rack middleware for providing JSON-P support.
  #
  # Full credit to Flinn Mueller (http://actsasflinn.com/) for this contribution.
  #
  class JSONP
    include Rack::Utils

    VALID_CALLBACK = /\A[a-zA-Z_$](?:\.?[\w$])*\z/

    # These hold the Unicode characters \u2028 and \u2029.
    #
    # They are defined in constants for Ruby 1.8 compatibility.
    #
    # In 1.8
    # "\u2028" # => "u2028"
    # "\u2029" # => "u2029"
    # In 1.9
    # "\342\200\250" # => "\u2028"
    # "\342\200\251" # => "\u2029"
    U2028, U2029 = ("\u2028" == 'u2028') ? ["\342\200\250", "\342\200\251"] : ["\u2028", "\u2029"]

    HEADERS_KLASS = Rack.release < "3" ? Utils::HeaderHash : Headers
    private_constant :HEADERS_KLASS

    def initialize(app)
      @app = app
    end

    # Proxies the request to the application, stripping out the JSON-P callback
    # method and padding the response with the appropriate callback format if
    # the returned body is application/json
    #
    # Changes nothing if no <tt>callback</tt> param is specified.
    #
    def call(env)
      request = Rack::Request.new(env)

      status, headers, response = @app.call(env)

      if STATUS_WITH_NO_ENTITY_BODY.include?(status)
        return status, headers, response
      end

      headers = HEADERS_KLASS.new.merge(headers)

      if is_json?(headers) && has_callback?(request)
        callback = request.params['callback']
        return bad_request unless valid_callback?(callback)

        response = pad(callback, response)

        # No longer json, its javascript!
        headers['Content-Type'] = headers['Content-Type'].gsub('json', 'javascript')

        # Set new Content-Length, if it was set before we mutated the response body
        if headers['Content-Length']
          length = response.map(&:bytesize).reduce(0, :+)
          headers['Content-Length'] = length.to_s
        end
      end

      [status, headers, response]
    end

    private

    def is_json?(headers)
      headers.key?('Content-Type') && headers['Content-Type'].include?('application/json')
    end

    def has_callback?(request)
      request.params.include?('callback') and not request.params['callback'].to_s.empty?
    end

    # See:
    # http://stackoverflow.com/questions/1661197/valid-characters-for-javascript-variable-names
    #
    # NOTE: Supports dots (.) since callbacks are often in objects:
    #
    def valid_callback?(callback)
      callback =~ VALID_CALLBACK
    end

    # Pads the response with the appropriate callback format according to the
    # JSON-P spec/requirements.
    #
    # The Rack response spec indicates that it should be enumerable. The
    # method of combining all of the data into a single string makes sense
    # since JSON is returned as a full string.
    #
    def pad(callback, response)
      body = response.to_enum.map do |s|
        # U+2028 and U+2029 are allowed inside strings in JSON (as all literal
        # Unicode characters) but JavaScript defines them as newline
        # seperators. Because no literal newlines are allowed in a string, this
        # causes a ParseError in the browser. We work around this issue by
        # replacing them with the escaped version. This should be safe because
        # according to the JSON spec, these characters are *only* valid inside
        # a string and should therefore not be present any other places.
        s.gsub(U2028, '\u2028').gsub(U2029, '\u2029')
      end.join

      # https://github.com/rack/rack-contrib/issues/46
      response.close if response.respond_to?(:close)

      ["/**/#{callback}(#{body})"]
    end

    def bad_request(body = "Bad Request")
      [ 400, { 'content-type' => 'text/plain', 'content-length' => body.bytesize.to_s }, [body] ]
    end

  end
end
