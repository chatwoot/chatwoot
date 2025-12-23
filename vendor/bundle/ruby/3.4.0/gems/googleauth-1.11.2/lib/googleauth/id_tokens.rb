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

require "googleauth/id_tokens/errors"
require "googleauth/id_tokens/key_sources"
require "googleauth/id_tokens/verifier"

module Google
  module Auth
    ##
    # ## Verifying Google ID tokens
    #
    # This module verifies ID tokens issued by Google. This can be used to
    # authenticate signed-in users using OpenID Connect. See
    # https://developers.google.com/identity/sign-in/web/backend-auth for more
    # information.
    #
    # ### Basic usage
    #
    # To verify an ID token issued by Google accounts:
    #
    #     payload = Google::Auth::IDTokens.verify_oidc the_token,
    #                                                  aud: "my-app-client-id"
    #
    # If verification succeeds, you will receive the token's payload as a hash.
    # If verification fails, an exception (normally a subclass of
    # {Google::Auth::IDTokens::VerificationError}) will be raised.
    #
    # To verify an ID token issued by the Google identity-aware proxy (IAP):
    #
    #     payload = Google::Auth::IDTokens.verify_iap the_token,
    #                                                 aud: "my-app-client-id"
    #
    # These methods will automatically download and cache the Google public
    # keys necessary to verify these tokens. They will also automatically
    # verify the issuer (`iss`) field for their respective types of ID tokens.
    #
    # ### Advanced usage
    #
    # If you want to provide your own public keys, either by pointing at a
    # custom URI or by providing the key data directly, use the Verifier class
    # and pass in a key source.
    #
    # To point to a custom URI that returns a JWK set:
    #
    #     source = Google::Auth::IDTokens::JwkHttpKeySource.new "https://example.com/jwk"
    #     verifier = Google::Auth::IDTokens::Verifier.new key_source: source
    #     payload = verifier.verify the_token, aud: "my-app-client-id"
    #
    # To provide key data directly:
    #
    #     jwk_data = {
    #       keys: [
    #         {
    #           alg: "ES256",
    #           crv: "P-256",
    #           kid: "LYyP2g",
    #           kty: "EC",
    #           use: "sig",
    #           x: "SlXFFkJ3JxMsXyXNrqzE3ozl_0913PmNbccLLWfeQFU",
    #           y: "GLSahrZfBErmMUcHP0MGaeVnJdBwquhrhQ8eP05NfCI"
    #         }
    #       ]
    #     }
    #     source = Google::Auth::IDTokens::StaticKeySource.from_jwk_set jwk_data
    #     verifier = Google::Auth::IDTokens::Verifier key_source: source
    #     payload = verifier.verify the_token, aud: "my-app-client-id"
    #
    module IDTokens
      ##
      # A list of issuers expected for Google OIDC-issued tokens.
      #
      # @return [Array<String>]
      #
      OIDC_ISSUERS = ["accounts.google.com", "https://accounts.google.com"].freeze

      ##
      # A list of issuers expected for Google IAP-issued tokens.
      #
      # @return [Array<String>]
      #
      IAP_ISSUERS = ["https://cloud.google.com/iap"].freeze

      ##
      # The URL for Google OAuth2 V3 public certs
      #
      # @return [String]
      #
      OAUTH2_V3_CERTS_URL = "https://www.googleapis.com/oauth2/v3/certs"

      ##
      # The URL for Google IAP public keys
      #
      # @return [String]
      #
      IAP_JWK_URL = "https://www.gstatic.com/iap/verify/public_key-jwk"

      class << self
        ##
        # The key source providing public keys that can be used to verify
        # ID tokens issued by Google OIDC.
        #
        # @return [Google::Auth::IDTokens::JwkHttpKeySource]
        #
        def oidc_key_source
          @oidc_key_source ||= JwkHttpKeySource.new OAUTH2_V3_CERTS_URL
        end

        ##
        # The key source providing public keys that can be used to verify
        # ID tokens issued by Google IAP.
        #
        # @return [Google::Auth::IDTokens::JwkHttpKeySource]
        #
        def iap_key_source
          @iap_key_source ||= JwkHttpKeySource.new IAP_JWK_URL
        end

        ##
        # Reset all convenience key sources. Used for testing.
        # @private
        #
        def forget_sources!
          @oidc_key_source = @iap_key_source = nil
          self
        end

        ##
        # A convenience method that verifies a token allegedly issued by Google
        # OIDC.
        #
        # @param token [String] The ID token to verify
        # @param aud [String,Array<String>,nil] The expected audience. At least
        #     one `aud` field in the token must match at least one of the
        #     provided audiences, or the verification will fail with
        #     {Google::Auth::IDToken::AudienceMismatchError}. If `nil` (the
        #     default), no audience checking is performed.
        # @param azp [String,Array<String>,nil] The expected authorized party
        #     (azp). At least one `azp` field in the token must match at least
        #     one of the provided values, or the verification will fail with
        #     {Google::Auth::IDToken::AuthorizedPartyMismatchError}. If `nil`
        #     (the default), no azp checking is performed.
        # @param iss [String,Array<String>,nil] The expected issuer. At least
        #     one `iss` field in the token must match at least one of the
        #     provided issuers, or the verification will fail with
        #     {Google::Auth::IDToken::IssuerMismatchError}. If `nil`, no issuer
        #     checking is performed. Default is to check against {OIDC_ISSUERS}.
        #
        # @return [Hash] The decoded token payload.
        # @raise [KeySourceError] if the key source failed to obtain public keys
        # @raise [VerificationError] if the token verification failed.
        #     Additional data may be available in the error subclass and message.
        #
        def verify_oidc token,
                        aud: nil,
                        azp: nil,
                        iss: OIDC_ISSUERS

          verifier = Verifier.new key_source: oidc_key_source,
                                  aud:        aud,
                                  azp:        azp,
                                  iss:        iss
          verifier.verify token
        end

        ##
        # A convenience method that verifies a token allegedly issued by Google
        # IAP.
        #
        # @param token [String] The ID token to verify
        # @param aud [String,Array<String>,nil] The expected audience. At least
        #     one `aud` field in the token must match at least one of the
        #     provided audiences, or the verification will fail with
        #     {Google::Auth::IDToken::AudienceMismatchError}. If `nil` (the
        #     default), no audience checking is performed.
        # @param azp [String,Array<String>,nil] The expected authorized party
        #     (azp). At least one `azp` field in the token must match at least
        #     one of the provided values, or the verification will fail with
        #     {Google::Auth::IDToken::AuthorizedPartyMismatchError}. If `nil`
        #     (the default), no azp checking is performed.
        # @param iss [String,Array<String>,nil] The expected issuer. At least
        #     one `iss` field in the token must match at least one of the
        #     provided issuers, or the verification will fail with
        #     {Google::Auth::IDToken::IssuerMismatchError}. If `nil`, no issuer
        #     checking is performed. Default is to check against {IAP_ISSUERS}.
        #
        # @return [Hash] The decoded token payload.
        # @raise [KeySourceError] if the key source failed to obtain public keys
        # @raise [VerificationError] if the token verification failed.
        #     Additional data may be available in the error subclass and message.
        #
        def verify_iap token,
                       aud: nil,
                       azp: nil,
                       iss: IAP_ISSUERS

          verifier = Verifier.new key_source: iap_key_source,
                                  aud:        aud,
                                  azp:        azp,
                                  iss:        iss
          verifier.verify token
        end
      end
    end
  end
end
