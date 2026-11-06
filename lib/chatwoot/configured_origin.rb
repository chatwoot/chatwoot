# frozen_string_literal: true

require 'uri'

class Chatwoot::ConfiguredOrigin
  class << self
    def from_env(name)
      value = ENV.fetch(name, nil)
      return if value.blank?

      uri = URI.parse(value)
      raise ArgumentError, "#{name} must be an HTTPS origin without a path, credentials, query, or fragment" unless valid_origin?(uri)

      uri.path = ''
      uri
    rescue URI::InvalidURIError
      raise ArgumentError, "#{name} must be a valid HTTPS origin"
    end

    private

    def valid_origin?(uri)
      valid_https_authority?(uri) && root_path?(uri) && query_and_fragment_absent?(uri) && valid_port?(uri.port)
    end

    def valid_https_authority?(uri)
      uri.is_a?(URI::HTTPS) && uri.host.present? && uri.userinfo.nil?
    end

    def root_path?(uri)
      uri.path.blank? || uri.path == '/'
    end

    def query_and_fragment_absent?(uri)
      uri.query.nil? && uri.fragment.nil?
    end

    def valid_port?(port)
      port.between?(1, 65_535)
    end
  end
end
