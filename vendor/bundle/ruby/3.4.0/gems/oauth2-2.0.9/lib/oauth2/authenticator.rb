# frozen_string_literal: true

require 'base64'

module OAuth2
  class Authenticator
    attr_reader :mode, :id, :secret

    def initialize(id, secret, mode)
      @id = id
      @secret = secret
      @mode = mode
    end

    # Apply the request credentials used to authenticate to the Authorization Server
    #
    # Depending on configuration, this might be as request params or as an
    # Authorization header.
    #
    # User-provided params and header take precedence.
    #
    # @param [Hash] params a Hash of params for the token endpoint
    # @return [Hash] params amended with appropriate authentication details
    def apply(params)
      case mode.to_sym
      when :basic_auth
        apply_basic_auth(params)
      when :request_body
        apply_params_auth(params)
      when :tls_client_auth
        apply_client_id(params)
      when :private_key_jwt
        params
      else
        raise NotImplementedError
      end
    end

    def self.encode_basic_auth(user, password)
      "Basic #{Base64.strict_encode64("#{user}:#{password}")}"
    end

  private

    # Adds client_id and client_secret request parameters if they are not
    # already set.
    def apply_params_auth(params)
      result = {}
      result['client_id'] = id unless id.nil?
      result['client_secret'] = secret unless secret.nil?
      result.merge(params)
    end

    # When using schemes that don't require the client_secret to be passed i.e TLS Client Auth,
    # we don't want to send the secret
    def apply_client_id(params)
      result = {}
      result['client_id'] = id unless id.nil?
      result.merge(params)
    end

    # Adds an `Authorization` header with Basic Auth credentials if and only if
    # it is not already set in the params.
    def apply_basic_auth(params)
      headers = params.fetch(:headers, {})
      headers = basic_auth_header.merge(headers)
      params.merge(headers: headers)
    end

    # @see https://datatracker.ietf.org/doc/html/rfc2617#section-2
    def basic_auth_header
      {'Authorization' => self.class.encode_basic_auth(id, secret)}
    end
  end
end
