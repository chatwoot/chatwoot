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

# This code was generated from OpenSearch API Spec.
# Update the code generation logic instead of modifying this file directly.

# frozen_string_literal: true

require 'opensearch/api/namespace/common'
require 'opensearch/api/utils'
require 'opensearch/api/actions/params_registry'

Dir[File.expand_path('api/actions/**/params_registry.rb', __dir__)].sort.each   { |f| require f }
Dir[File.expand_path('api/actions/**/*.rb', __dir__)].sort.each   { |f| require f }
Dir[File.expand_path('api/namespace/**/*.rb', __dir__)].sort.each { |f| require f }

module OpenSearch
  module API
    DEFAULT_SERIALIZER = MultiJson

    COMMON_PARAMS = [
      :ignore,                        # Client specific parameters
      :index, :id,                    # :index/:id
      :body,                          # Request body
      :node_id,                       # Cluster
      :name,                          # Alias, template, settings, warmer, ...
      :field                          # Get field mapping
    ]

    COMMON_QUERY_PARAMS = [
      :ignore,                        # Client specific parameters
      :format,                        # Search, Cat, ...
      :pretty,                        # Pretty-print the response
      :human,                         # Return numeric values in human readable format
      :filter_path,                   # Filter the JSON response
      :opaque_id                      # Use X-Opaque-Id
    ]

    HTTP_GET          = 'GET'
    HTTP_HEAD         = 'HEAD'
    HTTP_PATCH        = 'PATCH'
    HTTP_POST         = 'POST'
    HTTP_PUT          = 'PUT'
    HTTP_DELETE       = 'DELETE'

    UNDERSCORE_SEARCH = '_search'
    UNDERSCORE_ALL    = '_all'
    DEFAULT_DOC       = '_doc'

    # Auto-include all namespaces in the receiver
    def self.included(base)
      base.send :include,
                OpenSearch::API::Common,
                OpenSearch::API::Actions,
                OpenSearch::API::Cat,
                OpenSearch::API::Cluster,
                OpenSearch::API::DanglingIndices,
                OpenSearch::API::Features,
                OpenSearch::API::Http,
                OpenSearch::API::Indices,
                OpenSearch::API::Ingest,
                OpenSearch::API::Nodes,
                OpenSearch::API::Remote,
                OpenSearch::API::RemoteStore,
                OpenSearch::API::Security,
                OpenSearch::API::Shutdown,
                OpenSearch::API::Snapshot,
                OpenSearch::API::Tasks
    end

    # The serializer class
    def self.serializer
      settings[:serializer] || DEFAULT_SERIALIZER
    end

    # Access the module settings
    def self.settings
      @settings ||= {}
    end
  end
end
