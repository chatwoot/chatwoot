require "digest/sha1"
require "base64"
require "openssl"
require "signet"

module Signet # :nodoc:
  module OAuth1
    module RSASHA1
      def self.generate_signature \
          base_string, client_credential_secret, _token_credential_secret


        private_key = OpenSSL::PKey::RSA.new client_credential_secret
        signature = private_key.sign OpenSSL::Digest.new("SHA1"), base_string
        # using strict_encode64 because the encode64 method adds newline characters after ever 60 chars
        Base64.strict_encode64(signature).strip
      end
    end
  end
end
