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

require "googleauth/compute_engine"
require "googleauth/default_credentials"

module Google
  # Module Auth provides classes that provide Google-specific authorization
  # used to access Google APIs.
  module Auth
    NOT_FOUND_ERROR = <<~ERROR_MESSAGE.freeze
      Your credentials were not found. To set up Application Default
      Credentials for your environment, see
      https://cloud.google.com/docs/authentication/external/set-up-adc
    ERROR_MESSAGE

    module_function

    # Obtains the default credentials implementation to use in this
    # environment.
    #
    # Use this to obtain the Application Default Credentials for accessing
    # Google APIs.  Application Default Credentials are described in detail
    # at https://cloud.google.com/docs/authentication/production.
    #
    # If supplied, scope is used to create the credentials instance, when it can
    # be applied.  E.g, on google compute engine and for user credentials the
    # scope is ignored.
    #
    # @param scope [string|array|nil] the scope(s) to access
    # @param options [Hash] Connection options. These may be used to configure
    #     the `Faraday::Connection` used for outgoing HTTP requests. For
    #     example, if a connection proxy must be used in the current network,
    #     you may provide a connection with with the needed proxy options.
    #     The following keys are recognized:
    #     * `:default_connection` The connection object to use for token
    #       refresh requests.
    #     * `:connection_builder` A `Proc` that creates and returns a
    #       connection to use for token refresh requests.
    #     * `:connection` The connection to use to determine whether GCE
    #       metadata credentials are available.
    def get_application_default scope = nil, options = {}
      creds = DefaultCredentials.from_env(scope, options) ||
              DefaultCredentials.from_well_known_path(scope, options) ||
              DefaultCredentials.from_system_default_path(scope, options)
      return creds unless creds.nil?
      raise NOT_FOUND_ERROR unless GCECredentials.on_gce? options
      GCECredentials.new options.merge(scope: scope)
    end
  end
end
