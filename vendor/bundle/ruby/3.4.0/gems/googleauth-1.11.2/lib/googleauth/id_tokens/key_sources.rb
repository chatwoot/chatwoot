# frozen_string_literal: true

# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


require "base64"
require "json"
require "monitor"
require "net/http"
require "openssl"

require "jwt"

module Google
  module Auth
    module IDTokens
      ##
      # A public key used for verifying ID tokens.
      #
      # This includes the public key data, ID, and the algorithm used for
      # signature verification. RSA and Elliptical Curve (EC) keys are
      # supported.
      #
      class KeyInfo
        ##
        # Create a public key info structure.
        #
        # @param id [String] The key ID.
        # @param key [OpenSSL::PKey::RSA,OpenSSL::PKey::EC] The key itself.
        # @param algorithm [String] The algorithm (normally `RS256` or `ES256`)
        #
        def initialize id: nil, key: nil, algorithm: nil
          @id = id
          @key = key
          @algorithm = algorithm
        end

        ##
        # The key ID.
        # @return [String]
        #
        attr_reader :id

        ##
        # The key itself.
        # @return [OpenSSL::PKey::RSA,OpenSSL::PKey::EC]
        #
        attr_reader :key

        ##
        # The signature algorithm. (normally `RS256` or `ES256`)
        # @return [String]
        #
        attr_reader :algorithm

        class << self
          ##
          # Create a KeyInfo from a single JWK, which may be given as either a
          # hash or an unparsed JSON string.
          #
          # @param jwk [Hash,String] The JWK specification.
          # @return [KeyInfo]
          # @raise [KeySourceError] If the key could not be extracted from the
          #     JWK.
          #
          def from_jwk jwk
            jwk = symbolize_keys ensure_json_parsed jwk
            key = case jwk[:kty]
                  when "RSA"
                    extract_rsa_key jwk
                  when "EC"
                    extract_ec_key jwk
                  when nil
                    raise KeySourceError, "Key type not found"
                  else
                    raise KeySourceError, "Cannot use key type #{jwk[:kty]}"
                  end
            new id: jwk[:kid], key: key, algorithm: jwk[:alg]
          end

          ##
          # Create an array of KeyInfo from a JWK Set, which may be given as
          # either a hash or an unparsed JSON string.
          #
          # @param jwk [Hash,String] The JWK Set specification.
          # @return [Array<KeyInfo>]
          # @raise [KeySourceError] If a key could not be extracted from the
          #     JWK Set.
          #
          def from_jwk_set jwk_set
            jwk_set = symbolize_keys ensure_json_parsed jwk_set
            jwks = jwk_set[:keys]
            raise KeySourceError, "No keys found in jwk set" unless jwks
            jwks.map { |jwk| from_jwk jwk }
          end

          private

          def ensure_json_parsed input
            return input unless input.is_a? String
            JSON.parse input
          rescue JSON::ParserError
            raise KeySourceError, "Unable to parse JSON"
          end

          def symbolize_keys hash
            result = {}
            hash.each { |key, val| result[key.to_sym] = val }
            result
          end

          def extract_rsa_key jwk
            begin
              n_data = Base64.urlsafe_decode64 jwk[:n]
              e_data = Base64.urlsafe_decode64 jwk[:e]
            rescue ArgumentError
              raise KeySourceError, "Badly formatted key data"
            end
            n_bn = OpenSSL::BN.new n_data, 2
            e_bn = OpenSSL::BN.new e_data, 2
            sequence = [OpenSSL::ASN1::Integer.new(n_bn), OpenSSL::ASN1::Integer.new(e_bn)]
            rsa_key =  OpenSSL::PKey::RSA.new OpenSSL::ASN1::Sequence(sequence).to_der
            rsa_key.public_key
          end

          # @private
          CURVE_NAME_MAP = {
            "P-256"     => "prime256v1",
            "P-384"     => "secp384r1",
            "P-521"     => "secp521r1",
            "secp256k1" => "secp256k1"
          }.freeze

          def extract_ec_key jwk
            begin
              x_data = Base64.urlsafe_decode64 jwk[:x]
              y_data = Base64.urlsafe_decode64 jwk[:y]
            rescue ArgumentError
              raise KeySourceError, "Badly formatted key data"
            end
            curve_name = CURVE_NAME_MAP[jwk[:crv]]
            raise KeySourceError, "Unsupported EC curve #{jwk[:crv]}" unless curve_name
            group = OpenSSL::PKey::EC::Group.new curve_name
            x_hex = x_data.unpack1 "H*"
            y_hex = y_data.unpack1 "H*"
            bn = OpenSSL::BN.new ["04#{x_hex}#{y_hex}"].pack("H*"), 2
            point =  OpenSSL::PKey::EC::Point.new group, bn
            sequence = OpenSSL::ASN1::Sequence([
                                                 OpenSSL::ASN1::Sequence([OpenSSL::ASN1::ObjectId("id-ecPublicKey"),
                                                                          OpenSSL::ASN1::ObjectId(curve_name)]),
                                                 OpenSSL::ASN1::BitString(point.to_octet_string(:uncompressed))
                                               ])
            OpenSSL::PKey::EC.new sequence.to_der
          end
        end
      end

      ##
      # A key source that contains a static set of keys.
      #
      class StaticKeySource
        ##
        # Create a static key source with the given keys.
        #
        # @param keys [Array<KeyInfo>] The keys
        #
        def initialize keys
          @current_keys = Array(keys)
        end

        ##
        # Return the current keys. Does not perform any refresh.
        #
        # @return [Array<KeyInfo>]
        #
        attr_reader :current_keys
        alias refresh_keys current_keys

        class << self
          ##
          # Create a static key source containing a single key parsed from a
          # single JWK, which may be given as either a hash or an unparsed
          # JSON string.
          #
          # @param jwk [Hash,String] The JWK specification.
          # @return [StaticKeySource]
          #
          def from_jwk jwk
            new KeyInfo.from_jwk jwk
          end

          ##
          # Create a static key source containing multiple keys parsed from a
          # JWK Set, which may be given as either a hash or an unparsed JSON
          # string.
          #
          # @param jwk_set [Hash,String] The JWK Set specification.
          # @return [StaticKeySource]
          #
          def from_jwk_set jwk_set
            new KeyInfo.from_jwk_set jwk_set
          end
        end
      end

      ##
      # A base key source that downloads keys from a URI. Subclasses should
      # override {HttpKeySource#interpret_json} to parse the response.
      #
      class HttpKeySource
        ##
        # The default interval between retries in seconds (3600s = 1hr).
        #
        # @return [Integer]
        #
        DEFAULT_RETRY_INTERVAL = 3600

        ##
        # Create an HTTP key source.
        #
        # @param uri [String,URI] The URI from which to download keys.
        # @param retry_interval [Integer,nil] Override the retry interval in
        #     seconds. This is the minimum time between retries of failed key
        #     downloads.
        #
        def initialize uri, retry_interval: nil
          @uri = URI uri
          @retry_interval = retry_interval || DEFAULT_RETRY_INTERVAL
          @allow_refresh_at = Time.now
          @current_keys = []
          @monitor = Monitor.new
        end

        ##
        # The URI from which to download keys.
        # @return [Array<KeyInfo>]
        #
        attr_reader :uri

        ##
        # Return the current keys, without attempting to re-download.
        #
        # @return [Array<KeyInfo>]
        #
        attr_reader :current_keys

        ##
        # Attempt to re-download keys (if the retry interval has expired) and
        # return the new keys.
        #
        # @return [Array<KeyInfo>]
        # @raise [KeySourceError] if key retrieval failed.
        #
        def refresh_keys
          @monitor.synchronize do
            return @current_keys if Time.now < @allow_refresh_at
            @allow_refresh_at = Time.now + @retry_interval

            response = Net::HTTP.get_response uri
            raise KeySourceError, "Unable to retrieve data from #{uri}" unless response.is_a? Net::HTTPSuccess

            data = begin
              JSON.parse response.body
            rescue JSON::ParserError
              raise KeySourceError, "Unable to parse JSON"
            end

            @current_keys = Array(interpret_json(data))
          end
        end

        protected

        def interpret_json _data
          nil
        end
      end

      ##
      # A key source that downloads X509 certificates.
      # Used by the legacy OAuth V1 public certs endpoint.
      #
      class X509CertHttpKeySource < HttpKeySource
        ##
        # Create a key source that downloads X509 certificates.
        #
        # @param uri [String,URI] The URI from which to download keys.
        # @param algorithm [String] The algorithm to use for signature
        #     verification. Defaults to "`RS256`".
        # @param retry_interval [Integer,nil] Override the retry interval in
        #     seconds. This is the minimum time between retries of failed key
        #     downloads.
        #
        def initialize uri, algorithm: "RS256", retry_interval: nil
          super uri, retry_interval: retry_interval
          @algorithm = algorithm
        end

        protected

        def interpret_json data
          data.map do |id, cert_str|
            key = OpenSSL::X509::Certificate.new(cert_str).public_key
            KeyInfo.new id: id, key: key, algorithm: @algorithm
          end
        rescue OpenSSL::X509::CertificateError
          raise KeySourceError, "Unable to parse X509 certificates"
        end
      end

      ##
      # A key source that downloads a JWK set.
      #
      class JwkHttpKeySource < HttpKeySource
        ##
        # Create a key source that downloads a JWT Set.
        #
        # @param uri [String,URI] The URI from which to download keys.
        # @param retry_interval [Integer,nil] Override the retry interval in
        #     seconds. This is the minimum time between retries of failed key
        #     downloads.
        #
        def initialize uri, retry_interval: nil
          super uri, retry_interval: retry_interval
        end

        protected

        def interpret_json data
          KeyInfo.from_jwk_set data
        end
      end

      ##
      # A key source that aggregates other key sources. This means it will
      # aggregate the keys provided by its constituent sources. Additionally,
      # when asked to refresh, it will refresh all its constituent sources.
      #
      class AggregateKeySource
        ##
        # Create a key source that aggregates other key sources.
        #
        # @param sources [Array<key source>] The key sources to aggregate.
        #
        def initialize sources
          @sources = Array(sources)
        end

        ##
        # Return the current keys, without attempting to refresh.
        #
        # @return [Array<KeyInfo>]
        #
        def current_keys
          @sources.flat_map(&:current_keys)
        end

        ##
        # Attempt to refresh keys and return the new keys.
        #
        # @return [Array<KeyInfo>]
        # @raise [KeySourceError] if key retrieval failed.
        #
        def refresh_keys
          @sources.flat_map(&:refresh_keys)
        end
      end
    end
  end
end
