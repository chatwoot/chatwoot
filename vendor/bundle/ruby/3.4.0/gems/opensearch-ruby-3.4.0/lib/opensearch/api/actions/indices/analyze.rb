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
    module Indices
      module Actions
        # Performs the analysis process on a text and return the tokens breakdown of the text.
        #
        # @option arguments [String] :index The name of the index to scope the operation
        # @option arguments [Hash] :headers Custom HTTP headers
        # @option arguments [Hash] :body Define analyzer/tokenizer parameters and the text on which the analysis should be performed
        #
        #
        def analyze(arguments = {})
          headers = arguments.delete(:headers) || {}

          arguments = arguments.clone

          _index = arguments.delete(:index)

          method = if arguments[:body]
                     OpenSearch::API::HTTP_POST
                   else
                     OpenSearch::API::HTTP_GET
                   end

          path = if _index
                   "#{Utils.__listify(_index)}/_analyze"
                 else
                   '_analyze'
                 end
          params = Utils.__validate_and_extract_params arguments, ParamsRegistry.get(__method__)

          body = arguments[:body]
          perform_request(method, path, params, body, headers).body
        end

        # Register this action with its valid params when the module is loaded.
        #
        # @since 6.2.0
        ParamsRegistry.register(:analyze, [
          :index
        ].freeze)
      end
    end
  end
end
