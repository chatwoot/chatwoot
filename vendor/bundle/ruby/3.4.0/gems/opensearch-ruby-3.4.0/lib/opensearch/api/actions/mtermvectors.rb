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
    module Actions
      # Returns multiple termvectors in one request.
      #
      # @option arguments [String] :index The index in which the document resides.
      # @option arguments [List] :ids A comma-separated list of documents ids. You must define ids as parameter or set "ids" or "docs" in the request body
      # @option arguments [Boolean] :term_statistics Specifies if total term frequency and document frequency should be returned. Applies to all returned documents unless otherwise specified in body "params" or "docs".
      # @option arguments [Boolean] :field_statistics Specifies if document count, sum of document frequencies and sum of total term frequencies should be returned. Applies to all returned documents unless otherwise specified in body "params" or "docs".
      # @option arguments [List] :fields A comma-separated list of fields to return. Applies to all returned documents unless otherwise specified in body "params" or "docs".
      # @option arguments [Boolean] :offsets Specifies if term offsets should be returned. Applies to all returned documents unless otherwise specified in body "params" or "docs".
      # @option arguments [Boolean] :positions Specifies if term positions should be returned. Applies to all returned documents unless otherwise specified in body "params" or "docs".
      # @option arguments [Boolean] :payloads Specifies if term payloads should be returned. Applies to all returned documents unless otherwise specified in body "params" or "docs".
      # @option arguments [String] :preference Specify the node or shard the operation should be performed on (default: random) .Applies to all returned documents unless otherwise specified in body "params" or "docs".
      # @option arguments [String] :routing Specific routing value. Applies to all returned documents unless otherwise specified in body "params" or "docs".
      # @option arguments [Boolean] :realtime Specifies if requests are real-time as opposed to near-real-time (default: true).
      # @option arguments [Number] :version Explicit version number for concurrency control
      # @option arguments [String] :version_type Specific version type (options: internal, external, external_gte, force)
      # @option arguments [Hash] :headers Custom HTTP headers
      # @option arguments [Hash] :body Define ids, documents, parameters or a list of parameters per document here. You must at least provide a list of document ids. See documentation.
      #
      # *Deprecation notice*:
      # Specifying types in urls has been deprecated
      # Deprecated since version 7.0.0
      #
      #
      #
      def mtermvectors(arguments = {})
        headers = arguments.delete(:headers) || {}

        arguments = arguments.clone
        ids = arguments.delete(:ids)

        _index = arguments.delete(:index)

        method = if arguments[:body]
                   OpenSearch::API::HTTP_POST
                 else
                   OpenSearch::API::HTTP_GET
                 end

        path = if _index
                 "#{Utils.__listify(_index)}/_mtermvectors"
               else
                 '_mtermvectors'
               end
        params = Utils.__validate_and_extract_params arguments, ParamsRegistry.get(__method__)

        body = if ids
                 { ids: ids }
               else
                 arguments[:body]
               end
        perform_request(method, path, params, body, headers).body
      end

      # Register this action with its valid params when the module is loaded.
      #
      # @since 6.2.0
      ParamsRegistry.register(:mtermvectors, %i[
        ids
        term_statistics
        field_statistics
        fields
        offsets
        positions
        payloads
        preference
        routing
        realtime
        version
        version_type
      ].freeze)
    end
  end
end
