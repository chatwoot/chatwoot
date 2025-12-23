# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2023, by Samuel Williams.
# Copyright, 2022, by Jeremy Evans.

require 'webrick'
require 'stringio'

require 'rack/constants'
require_relative '../handler'
require_relative '../version'

require_relative '../stream'

module Rackup
  module Handler
    class WEBrick < ::WEBrick::HTTPServlet::AbstractServlet
      def self.run(app, **options)
        environment  = ENV['RACK_ENV'] || 'development'
        default_host = environment == 'development' ? 'localhost' : nil

        if !options[:BindAddress] || options[:Host]
          options[:BindAddress] = options.delete(:Host) || default_host
        end
        options[:Port] ||= 8080
        if options[:SSLEnable]
          require 'webrick/https'
        end

        @server = ::WEBrick::HTTPServer.new(options)
        @server.mount "/", Rackup::Handler::WEBrick, app
        yield @server if block_given?
        @server.start
      end

      def self.valid_options
        environment  = ENV['RACK_ENV'] || 'development'
        default_host = environment == 'development' ? 'localhost' : '0.0.0.0'

        {
          "Host=HOST" => "Hostname to listen on (default: #{default_host})",
          "Port=PORT" => "Port to listen on (default: 8080)",
        }
      end

      def self.shutdown
        if @server
          @server.shutdown
          @server = nil
        end
      end

      def initialize(server, app)
        super server
        @app = app
      end

      # This handles mapping the WEBrick request to a Rack input stream.
      class Input
        include Stream::Reader

        def initialize(request)
          @request = request

          @reader = Fiber.new do
            @request.body do |chunk|
              Fiber.yield(chunk)
            end

            Fiber.yield(nil)

            # End of stream:
            @reader = nil
          end
        end

        def close
          @request = nil
          @reader = nil
        end

        private

        # Read one chunk from the request body.
        def read_next
          @reader&.resume
        end
      end

      def service(req, res)
        env = req.meta_vars
        env.delete_if { |k, v| v.nil? }

        input = Input.new(req)

        env.update(
          ::Rack::RACK_INPUT => input,
          ::Rack::RACK_ERRORS => $stderr,
          ::Rack::RACK_URL_SCHEME => ["yes", "on", "1"].include?(env[::Rack::HTTPS]) ? "https" : "http",
          ::Rack::RACK_IS_HIJACK => true,
        )

        env[::Rack::QUERY_STRING] ||= ""
        unless env[::Rack::PATH_INFO] == ""
          path, n = req.request_uri.path, env[::Rack::SCRIPT_NAME].length
          env[::Rack::PATH_INFO] = path[n, path.length - n]
        end
        env[::Rack::REQUEST_PATH] ||= [env[::Rack::SCRIPT_NAME], env[::Rack::PATH_INFO]].join

        status, headers, body = @app.call(env)
        begin
          res.status = status

          if value = headers[::Rack::RACK_HIJACK]
            io_lambda = value
            body = nil
          elsif !body.respond_to?(:to_path) && !body.respond_to?(:each)
            io_lambda = body
            body = nil
          end

          if value = headers.delete('set-cookie')
            res.cookies.concat(Array(value))
          end

          headers.each do |key, value|
            # Skip keys starting with rack., per Rack SPEC
            next if key.start_with?('rack.')

            # Since WEBrick won't accept repeated headers,
            # merge the values per RFC 1945 section 4.2.
            value = value.join(", ") if Array === value
            res[key] = value
          end

          if io_lambda
            protocol = headers['rack.protocol'] || headers['upgrade']

            if protocol
              # Set all the headers correctly for an upgrade response:
              res.upgrade!(protocol)
            end
            res.body = io_lambda
          elsif body.respond_to?(:to_path)
            res.body = ::File.open(body.to_path, 'rb')
          else
            buffer = String.new
            body.each do |part|
              buffer << part
            end
            res.body = buffer
          end
        ensure
          body.close if body.respond_to?(:close)
        end
      end
    end

    register :webrick, WEBrick
  end
end
