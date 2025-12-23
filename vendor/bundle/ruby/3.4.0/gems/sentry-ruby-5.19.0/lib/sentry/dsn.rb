# frozen_string_literal: true

require "uri"

module Sentry
  class DSN
    PORT_MAP = { 'http' => 80, 'https' => 443 }.freeze
    REQUIRED_ATTRIBUTES = %w[host path public_key project_id].freeze

    attr_reader :scheme, :secret_key, :port, *REQUIRED_ATTRIBUTES

    def initialize(dsn_string)
      @raw_value = dsn_string

      uri = URI.parse(dsn_string)
      uri_path = uri.path.split('/')

      if uri.user
        # DSN-style string
        @project_id = uri_path.pop
        @public_key = uri.user
        @secret_key = !(uri.password.nil? || uri.password.empty?) ? uri.password : nil
      end

      @scheme = uri.scheme
      @host = uri.host
      @port = uri.port if uri.port
      @path = uri_path.join('/')
    end

    def valid?
      REQUIRED_ATTRIBUTES.all? { |k| public_send(k) }
    end

    def to_s
      @raw_value
    end

    def server
      server = "#{scheme}://#{host}"
      server += ":#{port}" unless port == PORT_MAP[scheme]
      server
    end

    def csp_report_uri
      "#{server}/api/#{project_id}/security/?sentry_key=#{public_key}"
    end

    def envelope_endpoint
      "#{path}/api/#{project_id}/envelope/"
    end
  end
end
