# frozen_string_literal: true

require "gserver"

module SidekiqAlive
  module Server
    # Simple HTTP server implementation
    #
    class HttpServer < GServer
      # Request class for HTTP server
      #
      class Request
        attr_reader :data, :header, :method, :path, :proto

        def initialize(data, method = nil, path = nil, proto = nil)
          @header = {}
          @data = data
          @method = method
          @path = path
          @proto = proto
        end

        def content_length
          len = @header["Content-Length"]
          return if len.nil?

          len.to_i
        end
      end

      # Response class for HTTP server
      #
      class Response
        attr_reader   :header
        attr_accessor :body, :status, :status_message

        def initialize(status = 200)
          @status = status
          @status_message = nil
          @header = {}
        end
      end

      def initialize(handle_obj, port, host, logger = Logger.new($stdout))
        @handler = handle_obj
        @logger = logger

        super(port, host, 1, nil, logger.debug?, logger.debug?)
      end

      private

      attr_reader :handler, :logger

      CRLF        = "\r\n"
      HTTP_PROTO  = "HTTP/1.1"
      SERVER_NAME = "SidekiqAlive/#{SidekiqAlive::VERSION} (Ruby/#{RUBY_VERSION})"

      # Default header for the server name
      DEFAULT_HEADER = {
        "Server" => SERVER_NAME,
      }

      # Mapping of status codes and error messages
      STATUS_CODE_MAPPING = {
        200 => "OK",
        400 => "Bad Request",
        403 => "Forbidden",
        404 => "Not Found",
        405 => "Method Not Allowed",
        411 => "Length Required",
        500 => "Internal Server Error",
      }

      def serve(io)
        # parse first line
        if io.gets =~ /^(\S+)\s+(\S+)\s+(\S+)/
          request = Request.new(io, ::Regexp.last_match(1), ::Regexp.last_match(2), ::Regexp.last_match(3))
        else
          io << http_resp(status_code: 400)
          return
        end

        # parse HTTP headers
        while (line = io.gets) !~ /^(\n|\r)/
          if line =~ /^([\w-]+):\s*(.*)$/
            request.header[::Regexp.last_match(1)] = ::Regexp.last_match(2).strip
          end
        end

        io.binmode
        response = Response.new

        # execute request handler
        handler.request_handler(request, response)

        http_response = http_resp(
          status_code: response.status,
          status_message: response.status_message,
          header: response.header,
          body: response.body,
        )

        # write response back to the client
        io << http_response
      rescue StandardError
        io << http_resp(status_code: 500)
      end

      def http_header(header = nil)
        new_header = DEFAULT_HEADER.dup
        new_header.merge(header) unless header.nil?

        new_header["Connection"] = "Keep-Alive"
        new_header["Date"] = http_date(Time.now)

        new_header
      end

      def http_resp(status_code:, status_message: nil, header: nil, body: nil)
        status_message ||= STATUS_CODE_MAPPING[status_code]
        status_line = "#{HTTP_PROTO} #{status_code} #{status_message}".rstrip + CRLF

        resp_header = http_header(header)
        resp_header["Content-Length"] = body.bytesize.to_s unless body.nil?
        header_lines = resp_header.map { |k, v| "#{k}: #{v}#{CRLF}" }.join

        [status_line, header_lines, CRLF, body].compact.join
      end

      def http_date(a_time)
        a_time.gmtime.strftime("%a, %d %b %Y %H:%M:%S GMT")
      end

      def log(msg)
        logger.debug(msg)
      end
    end
  end
end
