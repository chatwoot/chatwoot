# Copyright 2015 Google, Inc.
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

require "google-cloud-env"
require "googleauth/signet"

module Google
  # Module Auth provides classes that provide Google-specific authorization
  # used to access Google APIs.
  module Auth
    NO_METADATA_SERVER_ERROR = <<~ERROR.freeze
      Error code 404 trying to get security access token
      from Compute Engine metadata for the default service account. This
      may be because the virtual machine instance does not have permission
      scopes specified.
    ERROR
    UNEXPECTED_ERROR_SUFFIX = <<~ERROR.freeze
      trying to get security access token from Compute Engine metadata for
      the default service account
    ERROR

    # Extends Signet::OAuth2::Client so that the auth token is obtained from
    # the GCE metadata server.
    class GCECredentials < Signet::OAuth2::Client
      # @private Unused and deprecated but retained to prevent breaking changes
      DEFAULT_METADATA_HOST = "169.254.169.254".freeze

      # @private Unused and deprecated but retained to prevent breaking changes
      COMPUTE_AUTH_TOKEN_URI =
        "http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/token".freeze
      # @private Unused and deprecated but retained to prevent breaking changes
      COMPUTE_ID_TOKEN_URI =
        "http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/identity".freeze
      # @private Unused and deprecated but retained to prevent breaking changes
      COMPUTE_CHECK_URI = "http://169.254.169.254".freeze

      class << self
        # @private Unused and deprecated
        def metadata_host
          ENV.fetch "GCE_METADATA_HOST", DEFAULT_METADATA_HOST
        end

        # @private Unused and deprecated
        def compute_check_uri
          "http://#{metadata_host}".freeze
        end

        # @private Unused and deprecated
        def compute_auth_token_uri
          "#{compute_check_uri}/computeMetadata/v1/instance/service-accounts/default/token".freeze
        end

        # @private Unused and deprecated
        def compute_id_token_uri
          "#{compute_check_uri}/computeMetadata/v1/instance/service-accounts/default/identity".freeze
        end

        # Detect if this appear to be a GCE instance, by checking if metadata
        # is available.
        # The parameters are deprecated and unused.
        def on_gce? _options = {}, _reload = false # rubocop:disable Style/OptionalBooleanParameter
          Google::Cloud.env.metadata?
        end

        def reset_cache
          Google::Cloud.env.compute_metadata.reset_existence!
          Google::Cloud.env.compute_metadata.cache.expire_all!
        end
        alias unmemoize_all reset_cache
      end

      # @private Temporary; remove when universe domain metadata endpoint is stable (see b/349488459).
      attr_accessor :disable_universe_domain_check

      # Construct a GCECredentials
      def initialize options = {}
        # Override the constructor to remember whether the universe domain was
        # overridden by a constructor argument.
        @universe_domain_overridden = options["universe_domain"] || options[:universe_domain] ? true : false
        # TODO: Remove when universe domain metadata endpoint is stable (see b/349488459).
        @disable_universe_domain_check = true
        super options
      end

      # Overrides the super class method to change how access tokens are
      # fetched.
      def fetch_access_token _options = {}
        if token_type == :id_token
          query = { "audience" => target_audience, "format" => "full" }
          entry = "service-accounts/default/identity"
        else
          query = {}
          entry = "service-accounts/default/token"
        end
        query[:scopes] = Array(scope).join "," if scope
        begin
          resp = Google::Cloud.env.lookup_metadata_response "instance", entry, query: query
          case resp.status
          when 200
            build_token_hash resp.body, resp.headers["content-type"], resp.retrieval_monotonic_time
          when 403, 500
            msg = "Unexpected error code #{resp.status} #{UNEXPECTED_ERROR_SUFFIX}"
            raise Signet::UnexpectedStatusError, msg
          when 404
            raise Signet::AuthorizationError, NO_METADATA_SERVER_ERROR
          else
            msg = "Unexpected error code #{resp.status} #{UNEXPECTED_ERROR_SUFFIX}"
            raise Signet::AuthorizationError, msg
          end
        rescue Google::Cloud::Env::MetadataServerNotResponding => e
          raise Signet::AuthorizationError, e.message
        end
      end

      private

      def build_token_hash body, content_type, retrieval_time
        hash =
          if ["text/html", "application/text"].include? content_type
            parse_encoded_token body
          else
            Signet::OAuth2.parse_credentials body, content_type
          end
        add_universe_domain_to hash
        adjust_for_stale_expires_in hash, retrieval_time
        hash
      end

      def parse_encoded_token body
        hash = { token_type.to_s => body }
        if token_type == :id_token
          expires_at = expires_at_from_id_token body
          hash["expires_at"] = expires_at if expires_at
        end
        hash
      end

      def add_universe_domain_to hash
        return if @universe_domain_overridden
        universe_domain =
          if disable_universe_domain_check
            # TODO: Remove when universe domain metadata endpoint is stable (see b/349488459).
            "googleapis.com"
          else
            Google::Cloud.env.lookup_metadata "universe", "universe-domain"
          end
        universe_domain = "googleapis.com" if !universe_domain || universe_domain.empty?
        hash["universe_domain"] = universe_domain.strip
      end

      # The response might have been cached, which means expires_in might be
      # stale. Update it based on the time since the data was retrieved.
      # We also ensure expires_in is conservative; subtracting at least 1
      # second to offset any skew from metadata server latency.
      def adjust_for_stale_expires_in hash, retrieval_time
        return unless hash["expires_in"].is_a? Numeric
        offset = 1 + (Process.clock_gettime(Process::CLOCK_MONOTONIC) - retrieval_time).round
        hash["expires_in"] -= offset if offset.positive?
        hash["expires_in"] = 0 if hash["expires_in"].negative?
      end
    end
  end
end
