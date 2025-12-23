# SPDX-License-Identifier: Apache-2.0
#
# The OpenSearch Contributors require contributions made to
# this file be licensed under the Apache-2.0 license or a
# compatible open source license.
#
# Modifications Copyright OpenSearch Contributors. See
# GitHub history for details.
#
# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

module OpenSearch
  module API
    module Common
      module Actions; end

      module Client
        # Base client wrapper
        #
        module Base
          attr_reader :client

          def initialize(client)
            @client = client
          end
        end

        # Delegates the `perform_request` method to the wrapped client
        #
        def perform_request(method, path, params = {}, body = nil, headers = nil)
          client.perform_request method, path, params, body, headers
        end

        def perform_request_simple_ignore404(method, path, params, body, headers)
          Utils.__rescue_from_not_found do
            perform_request(method, path, params, body, headers).status == 200
          end
        end

        def perform_request_complex_ignore404(method, path, params, body, headers, arguments)
          if Array(arguments[:ignore]).include?(404)
            Utils.__rescue_from_not_found { perform_request(method, path, params, body, headers).body }
          else
            perform_request(method, path, params, body, headers).body
          end
        end

        def perform_request_ping(method, path, params, body, headers)
          perform_request(method, path, params, body, headers).status == 200
        rescue StandardError => e
          raise e unless e.class.to_s =~ /NotFound|ConnectionFailed/ || e.message =~ /Not\s*Found|404|ConnectionFailed/i
          false
        end
      end
    end
  end
end
