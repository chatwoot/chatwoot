require "signet"

module Signet # :nodoc:
  module OAuth1
    module PLAINTEXT
      def self.generate_signature \
          _base_string, client_credential_secret, token_credential_secret

        # Both the client secret and token secret must be escaped
        client_credential_secret =
          Signet::OAuth1.encode client_credential_secret
        token_credential_secret =
          Signet::OAuth1.encode token_credential_secret
        # The key for the signature is just the client secret and token
        # secret joined by the '&' character.  If the token secret is omitted,
        # the '&' must still be present.
        key = [client_credential_secret, token_credential_secret].join "&"
        Signet::OAuth1.encode(key).strip
      end
    end
  end
end
