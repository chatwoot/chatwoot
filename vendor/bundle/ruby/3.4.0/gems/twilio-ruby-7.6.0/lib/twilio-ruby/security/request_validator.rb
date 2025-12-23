# frozen_string_literal: true

module Twilio
  module Security
    class RequestValidator
      ##
      # Initialize a Request Validator. auth_token will either be grabbed from the global Twilio object or you can
      # pass it in here.
      #
      # @param [String] auth_token Your account auth token, used to sign requests
      def initialize(auth_token = nil)
        @auth_token = auth_token || Twilio.auth_token
        raise ArgumentError, 'Auth token is required' if @auth_token.nil?
      end

      ##
      # Validates that after hashing a request with Twilio's request-signing algorithm
      # (https://www.twilio.com/docs/usage/security#validating-requests), the hash matches the signature parameter
      #
      # @param [String] url The url sent to your server, including any query parameters
      # @param [String, Hash, #to_unsafe_h] params In most cases, this is the POST parameters as a hash. If you received
      #   a bodySHA256 parameter in the query string, this parameter can instead be the POST body as a string to
      #   validate JSON or other text-based payloads that aren't x-www-form-urlencoded.
      # @param [String] signature The expected signature, from the X-Twilio-Signature header of the request
      #
      # @return [Boolean] whether or not the computed signature matches the signature parameter
      def validate(url, params, signature)
        parsed_url = URI(url)
        url_with_port = add_port(parsed_url)
        url_without_port = remove_port(parsed_url)

        valid_body = true # default succeed, since body not always provided
        params_hash = body_or_hash(params)
        unless params_hash.is_a? Enumerable
          body_hash = URI.decode_www_form(parsed_url.query || '').to_h['bodySHA256']
          params_hash = build_hash_for(params)
          valid_body = !(params_hash.nil? || body_hash.nil?) && secure_compare(params_hash, body_hash)
          params_hash = {}
        end

        # Check signature of the url with and without port numbers
        # since signature generation on the back end is inconsistent
        valid_signature_with_port = secure_compare(build_signature_for(url_with_port, params_hash), signature)
        valid_signature_without_port = secure_compare(build_signature_for(url_without_port, params_hash), signature)

        valid_body && (valid_signature_with_port || valid_signature_without_port)
      end

      ##
      # Build a SHA256 hash for a body string
      #
      # @param [String] body String to hash
      #
      # @return [String] A hex-encoded SHA256 of the body string
      def build_hash_for(body)
        hasher = OpenSSL::Digest.new('sha256')
        hasher.hexdigest(body)
      end

      ##
      # Build a SHA1-HMAC signature for a url and parameter hash
      #
      # @param [String] url The request url, including any query parameters
      # @param [#join] params The POST parameters
      #
      # @return [String] A base64 encoded SHA1-HMAC
      def build_signature_for(url, params)
        data = url + params.sort.join
        digest = OpenSSL::Digest.new('sha1')
        Base64.strict_encode64(OpenSSL::HMAC.digest(digest, @auth_token, data))
      end

      private

      # Compares two strings in constant time to avoid timing attacks.
      # Borrowed from ActiveSupport::MessageVerifier.
      # https://github.com/rails/rails/blob/master/activesupport/lib/active_support/message_verifier.rb
      def secure_compare(a, b)
        return false unless a.bytesize == b.bytesize

        l = a.unpack("C#{a.bytesize}")

        res = 0
        b.each_byte { |byte| res |= byte ^ l.shift }
        res.zero?
      end

      # `ActionController::Parameters` no longer, as of Rails 5, inherits
      # from `Hash` so the `sort` method, used above in `build_signature_for`
      # is deprecated.
      #
      # `to_unsafe_h` was introduced in Rails 4.2.1, before then it is still
      # possible to sort on an ActionController::Parameters object.
      #
      # We use `to_unsafe_h` as `to_h` returns a hash of the permitted
      # parameters only and we need all the parameters to create the signature.
      def body_or_hash(params_or_body)
        if params_or_body.respond_to?(:to_unsafe_h)
          params_or_body.to_unsafe_h
        else
          params_or_body
        end
      end

      ##
      # Adds the standard port to the url if it doesn't already have one
      #
      # @param [URI] parsed_url The parsed request url
      #
      # @return [String] The URL with a port number
      def add_port(parsed_url)
        if parsed_url.port.nil? || parsed_url.port == parsed_url.default_port
          build_url_with_port_for(parsed_url)
        else
          parsed_url.to_s
        end
      end

      ##
      # Removes the port from the url
      #
      # @param [URI] parsed_url The parsed request url
      #
      # @return [String] The URL without a port number
      def remove_port(parsed_url)
        parsed_url.port = nil
        parsed_url.to_s
      end

      ##
      # Builds the url from its component pieces, with the standard port
      #
      # @param [URI] parsed_url The parsed request url
      #
      # @return [String] The URL with the standard port number
      def build_url_with_port_for(parsed_url)
        url = ''

        url += parsed_url.scheme ? "#{parsed_url.scheme}://" : ''
        url += parsed_url.userinfo ? "#{parsed_url.userinfo}@" : ''
        url += parsed_url.host ? "#{parsed_url.host}:#{parsed_url.port}" : ''
        url += parsed_url.path
        url += parsed_url.query ? "?#{parsed_url.query}" : ''
        url += parsed_url.fragment ? "##{parsed_url.fragment}" : ''

        url
      end
    end
  end
end
