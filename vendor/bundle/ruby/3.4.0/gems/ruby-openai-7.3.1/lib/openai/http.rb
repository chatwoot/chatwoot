require "event_stream_parser"

require_relative "http_headers"

module OpenAI
  module HTTP
    include HTTPHeaders

    def get(path:, parameters: nil)
      parse_jsonl(conn.get(uri(path: path), parameters) do |req|
        req.headers = headers
      end&.body)
    end

    def post(path:)
      parse_jsonl(conn.post(uri(path: path)) do |req|
        req.headers = headers
      end&.body)
    end

    def json_post(path:, parameters:, query_parameters: {})
      conn.post(uri(path: path)) do |req|
        configure_json_post_request(req, parameters)
        req.params = req.params.merge(query_parameters)
      end&.body
    end

    def multipart_post(path:, parameters: nil)
      conn(multipart: true).post(uri(path: path)) do |req|
        req.headers = headers.merge({ "Content-Type" => "multipart/form-data" })
        req.body = multipart_parameters(parameters)
      end&.body
    end

    def delete(path:)
      conn.delete(uri(path: path)) do |req|
        req.headers = headers
      end&.body
    end

    private

    def parse_jsonl(response)
      return unless response
      return response unless response.is_a?(String)

      # Convert a multiline string of JSON objects to a JSON array.
      response = response.gsub("}\n{", "},{").prepend("[").concat("]")

      JSON.parse(response)
    end

    # Given a proc, returns an outer proc that can be used to iterate over a JSON stream of chunks.
    # For each chunk, the inner user_proc is called giving it the JSON object. The JSON object could
    # be a data object or an error object as described in the OpenAI API documentation.
    #
    # @param user_proc [Proc] The inner proc to call for each JSON object in the chunk.
    # @return [Proc] An outer proc that iterates over a raw stream, converting it to JSON.
    def to_json_stream(user_proc:)
      parser = EventStreamParser::Parser.new

      proc do |chunk, _bytes, env|
        if env && env.status != 200
          raise_error = Faraday::Response::RaiseError.new
          raise_error.on_complete(env.merge(body: try_parse_json(chunk)))
        end

        parser.feed(chunk) do |_type, data|
          user_proc.call(JSON.parse(data)) unless data == "[DONE]"
        end
      end
    end

    def conn(multipart: false)
      connection = Faraday.new do |f|
        f.options[:timeout] = @request_timeout
        f.request(:multipart) if multipart
        f.use MiddlewareErrors if @log_errors
        f.response :raise_error
        f.response :json
      end

      @faraday_middleware&.call(connection)

      connection
    end

    def uri(path:)
      if azure?
        base = File.join(@uri_base, path)
        "#{base}?api-version=#{@api_version}"
      elsif @uri_base.include?(@api_version)
        File.join(@uri_base, path)
      else
        File.join(@uri_base, @api_version, path)
      end
    end

    def multipart_parameters(parameters)
      parameters&.transform_values do |value|
        next value unless value.respond_to?(:close) # File or IO object.

        # Faraday::UploadIO does not require a path, so we will pass it
        # only if it is available. This allows StringIO objects to be
        # passed in as well.
        path = value.respond_to?(:path) ? value.path : nil
        # Doesn't seem like OpenAI needs mime_type yet, so not worth
        # the library to figure this out. Hence the empty string
        # as the second argument.
        Faraday::UploadIO.new(value, "", path)
      end
    end

    def configure_json_post_request(req, parameters)
      req_parameters = parameters.dup

      if parameters[:stream].respond_to?(:call)
        req.options.on_data = to_json_stream(user_proc: parameters[:stream])
        req_parameters[:stream] = true # Necessary to tell OpenAI to stream.
      elsif parameters[:stream]
        raise ArgumentError, "The stream parameter must be a Proc or have a #call method"
      end

      req.headers = headers
      req.body = req_parameters.to_json
    end

    def try_parse_json(maybe_json)
      JSON.parse(maybe_json)
    rescue JSON::ParserError
      maybe_json
    end
  end
end
