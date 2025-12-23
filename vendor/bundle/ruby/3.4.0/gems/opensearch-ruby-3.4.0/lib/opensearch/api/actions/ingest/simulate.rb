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
    module Ingest
      module Actions
        # Allows to simulate a pipeline with example documents.
        #
        # @option arguments [String] :id Pipeline ID
        # @option arguments [Boolean] :verbose Verbose mode. Display data output for each processor in executed pipeline
        # @option arguments [Hash] :headers Custom HTTP headers
        # @option arguments [Hash] :body The simulate definition (*Required*)
        #
        #
        def simulate(arguments = {})
          raise ArgumentError, "Required argument 'body' missing" unless arguments[:body]

          headers = arguments.delete(:headers) || {}

          arguments = arguments.clone

          _id = arguments.delete(:id)

          method = OpenSearch::API::HTTP_POST
          path   = if _id
                     "_ingest/pipeline/#{Utils.__listify(_id)}/_simulate"
                   else
                     '_ingest/pipeline/_simulate'
                   end
          params = Utils.__validate_and_extract_params arguments, ParamsRegistry.get(__method__)

          body = arguments[:body]
          perform_request(method, path, params, body, headers).body
        end

        # Register this action with its valid params when the module is loaded.
        #
        # @since 6.2.0
        ParamsRegistry.register(:simulate, [
          :verbose
        ].freeze)
      end
    end
  end
end
