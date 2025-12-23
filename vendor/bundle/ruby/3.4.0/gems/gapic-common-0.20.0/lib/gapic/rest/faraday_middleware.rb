# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
require "faraday"

module Gapic
  module Rest
    # Registers the middleware with Faraday
    module FaradayMiddleware
      ##
      # @private
      # Request middleware that constructs the Authorization HTTP header
      # using ::Google::Auth::Credentials
      #
      class GoogleAuthorization < Faraday::Middleware
        ##
        # @private
        # @param app [#call]
        # @param credentials [Google::Auth::Credentials, Signet::OAuth2::Client, Symbol, Proc]
        #   Provides the means for authenticating requests made by
        #   the client. This parameter can be many types:
        #   * A `Google::Auth::Credentials` uses a the properties of its represented keyfile for authenticating requests
        #     made by this client.
        #   * A `Signet::OAuth2::Client` object used to apply the OAuth credentials.
        #   * A `Proc` will be used as an updater_proc for the auth token.
        #   * A `Symbol` is treated as a signal that authentication is not required.
        #
        def initialize app, credentials
          @updater_proc = case credentials
                          when Symbol
                            credentials
                          else
                            updater_proc = credentials.updater_proc if credentials.respond_to? :updater_proc
                            updater_proc ||= credentials if credentials.is_a? Proc
                            raise ArgumentError, "invalid credentials (#{credentials.class})" if updater_proc.nil?
                            updater_proc
                          end
          super app
        end

        # @private
        # @param env [Faraday::Env]
        def call env
          unless @updater_proc.is_a? Symbol
            auth_hash = @updater_proc.call({})
            env.request_headers["Authorization"] = auth_hash[:authorization]
          end

          @app.call env
        end
      end

      Faraday::Request.register_middleware google_authorization: -> { GoogleAuthorization }
    end
  end
end
