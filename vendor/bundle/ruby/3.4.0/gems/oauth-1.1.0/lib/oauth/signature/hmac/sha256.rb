# frozen_string_literal: true

require "oauth/signature/base"

module OAuth
  module Signature
    module HMAC
      class SHA256 < OAuth::Signature::Base
        implements "hmac-sha256"

        def body_hash
          Base64.encode64(OpenSSL::Digest.digest("SHA256", request.body || "")).chomp.delete("\n")
        end

        private

        def digest
          OpenSSL::HMAC.digest(OpenSSL::Digest.new("sha256"), secret, signature_base_string)
        end
      end
    end
  end
end
