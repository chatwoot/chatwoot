# frozen_string_literal: true

require "oauth/signature/base"

module OAuth
  module Signature
    module RSA
      class SHA1 < OAuth::Signature::Base
        implements "rsa-sha1"

        def ==(other)
          public_key.verify(OpenSSL::Digest.new("SHA1"),
                            Base64.decode64(other.is_a?(Array) ? other.first : other), signature_base_string)
        end

        def public_key
          case consumer_secret
          when String
            decode_public_key
          when OpenSSL::X509::Certificate
            consumer_secret.public_key
          else
            consumer_secret
          end
        end

        def body_hash
          Base64.encode64(OpenSSL::Digest.digest("SHA1", request.body || "")).chomp.delete("\n")
        end

        private

        def decode_public_key
          case consumer_secret
          when /-----BEGIN CERTIFICATE-----/
            OpenSSL::X509::Certificate.new(consumer_secret).public_key
          else
            OpenSSL::PKey::RSA.new(consumer_secret)
          end
        end

        def digest
          private_key = OpenSSL::PKey::RSA.new(
            if options[:private_key_file]
              File.read(options[:private_key_file])
            elsif options[:private_key]
              options[:private_key]
            else
              consumer_secret
            end
          )

          private_key.sign(OpenSSL::Digest.new("SHA1"), signature_base_string)
        end
      end
    end
  end
end
