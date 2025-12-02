require 'net/http'
require 'resolv'

module Captain
  module Tools
    class HttpTool < BasePublicTool
      # Constants for security limits
      MAX_BODY_SIZE = 1.megabyte

      # Blocked IP ranges (RFC 1918, Loopback, Link-Local)
      BLOCKED_NETWORKS = [
        IPAddr.new('127.0.0.0/8'),
        IPAddr.new('10.0.0.0/8'),
        IPAddr.new('172.16.0.0/12'),
        IPAddr.new('192.168.0.0/16'),
        IPAddr.new('169.254.0.0/16'),
        IPAddr.new('::1'),
        IPAddr.new('fc00::/7'),
        IPAddr.new('fe80::/10')
      ].freeze

      def initialize(assistant, custom_tool_record)
        @custom_tool = custom_tool_record
        super(assistant)
      end

      def active?
        @custom_tool.enabled?
      end

      def perform(_context, **args)
        target_url = @custom_tool.build_request_url(args)
        payload = @custom_tool.build_request_body(args)

        response = send_request(target_url, payload)

        @custom_tool.format_response(response.body)
      rescue StandardError => e
        Rails.logger.error("Custom Tool Error [#{@custom_tool.slug}]: #{e.message}")
        "Error executing tool: #{e.message}"
      end

      private

      def send_request(url, body)
        uri = URI.parse(url)
        ensure_public_address!(uri.host)

        http_client = Net::HTTP.new(uri.host, uri.port)
        configure_client(http_client, uri)

        request = create_request(uri, body)
        add_auth_headers(request)

        response = http_client.request(request)
        verify_response!(response)

        response
      end

      def ensure_public_address!(host)
        ips = Resolv.getaddresses(host)

        ips.each do |ip|
          addr = IPAddr.new(ip)
          raise "Access denied to private IP: #{ip}" if BLOCKED_NETWORKS.any? { |net| net.include?(addr) }
        end
      rescue Resolv::ResolvError
        raise "Could not resolve hostname: #{host}"
      end

      def configure_client(http, uri)
        http.use_ssl = (uri.scheme == 'https')
        http.open_timeout = 5
        http.read_timeout = 15
      end

      def create_request(uri, body)
        method_class = Net::HTTP.const_get(@custom_tool.http_method.capitalize)
        req = method_class.new(uri)

        if body.present?
          req.body = body
          req['Content-Type'] = 'application/json'
        end

        req
      end

      def add_auth_headers(req)
        # Add custom headers
        @custom_tool.build_auth_headers.each do |k, v|
          req[k] = v
        end

        # Add Basic Auth if needed
        creds = @custom_tool.build_basic_auth_credentials
        req.basic_auth(*creds) if creds
      end

      def verify_response!(resp)
        raise "Remote service returned error: #{resp.code}" unless resp.is_a?(Net::HTTPSuccess)

        check_size!(resp)
      end

      def check_size!(resp)
        size = resp['content-length']&.to_i || resp.body&.bytesize || 0

        return unless size > MAX_BODY_SIZE

        raise "Response too large (#{size} bytes). Limit is #{MAX_BODY_SIZE} bytes."
      end
    end
  end
end
