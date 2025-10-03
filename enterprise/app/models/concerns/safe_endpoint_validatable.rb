module Concerns::SafeEndpointValidatable
  extend ActiveSupport::Concern

  FRONTEND_HOST = URI.parse(ENV.fetch('FRONTEND_URL', 'http://localhost:3000')).host.freeze
  DISALLOWED_HOSTS = ['localhost', /\.local\z/i].freeze

  included do
    validate :validate_safe_endpoint_url
  end

  private

  def validate_safe_endpoint_url
    return if endpoint_url.blank?

    uri = parse_endpoint_uri
    return errors.add(:endpoint_url, 'must be a valid URL') unless uri

    validate_endpoint_scheme(uri)
    validate_endpoint_host(uri)
    validate_not_ip_address(uri)
    validate_no_unicode_chars(uri)
  end

  def parse_endpoint_uri
    # Strip Liquid template syntax for validation
    # Replace {{ variable }} with a placeholder value
    sanitized_url = endpoint_url.gsub(/\{\{[^}]+\}\}/, 'placeholder')
    URI.parse(sanitized_url)
  rescue URI::InvalidURIError
    nil
  end

  def validate_endpoint_scheme(uri)
    return if uri.scheme == 'https'

    errors.add(:endpoint_url, 'must use HTTPS protocol')
  end

  def validate_endpoint_host(uri)
    if uri.host.blank?
      errors.add(:endpoint_url, 'must have a valid hostname')
      return
    end

    if uri.host == FRONTEND_HOST
      errors.add(:endpoint_url, 'cannot point to the application itself')
      return
    end

    DISALLOWED_HOSTS.each do |pattern|
      matched = if pattern.is_a?(Regexp)
                  uri.host =~ pattern
                else
                  uri.host.downcase == pattern
                end

      next unless matched

      errors.add(:endpoint_url, 'cannot use disallowed hostname')
      break
    end
  end

  def validate_not_ip_address(uri)
    # Check for IPv4
    if /\A\d+\.\d+\.\d+\.\d+\z/.match?(uri.host)
      errors.add(:endpoint_url, 'cannot be an IP address, must be a hostname')
      return
    end

    # Check for IPv6
    return unless uri.host.include?(':')

    errors.add(:endpoint_url, 'cannot be an IP address, must be a hostname')
  end

  def validate_no_unicode_chars(uri)
    return unless uri.host
    return if /\A[\x00-\x7F]+\z/.match?(uri.host)

    errors.add(:endpoint_url, 'hostname cannot contain non-ASCII characters')
  end
end
