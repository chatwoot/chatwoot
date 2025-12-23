# frozen_string_literal: true

require_relative 'rack_transport'

module FastMcp
  module Transports
    class AuthenticatedRackTransport < RackTransport
      def initialize(app, server, options = {})
        super

        @auth_token = options[:auth_token]
        @auth_header_name = options[:auth_header_name] || 'Authorization'
        @auth_exempt_paths = options[:auth_exempt_paths] || []
        @auth_enabled = !@auth_token.nil?
      end

      def handle_mcp_request(request, env)
        if auth_enabled? && !exempt_from_auth?(request.path)
          auth_header = request.env["HTTP_#{@auth_header_name.upcase.gsub('-', '_')}"]
          token = auth_header&.gsub('Bearer ', '')

          return unauthorized_response(request) unless valid_token?(token)
        end

        super
      end

      private

      def auth_enabled?
        @auth_enabled
      end

      def exempt_from_auth?(path)
        @auth_exempt_paths.any? { |exempt_path| path.start_with?(exempt_path) }
      end

      def valid_token?(token)
        token == @auth_token
      end

      def unauthorized_response(request)
        @logger.error('Unauthorized request: Invalid or missing authentication token')
        body = JSON.generate(
          {
            jsonrpc: '2.0',
            error: {
              code: -32_000,
              message: 'Unauthorized: Invalid or missing authentication token'
            },
            id: extract_request_id(request)
          }
        )

        [401, { 'Content-Type' => 'application/json' }, [body]]
      end

      def extract_request_id(request)
        return nil unless request.post?

        begin
          body = request.body.read
          request.body.rewind
          JSON.parse(body)['id']
        rescue StandardError
          nil
        end
      end
    end
  end
end
