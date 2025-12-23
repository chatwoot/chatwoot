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

require 'opensearch/dsl/utils'
require 'opensearch/dsl/search/base_component'
require 'opensearch/dsl/search/base_compound_filter_component'
require 'opensearch/dsl/search/base_aggregation_component'
require 'opensearch/dsl/search/query'
require 'opensearch/dsl/search/filter'
require 'opensearch/dsl/search/aggregation'
require 'opensearch/dsl/search/highlight'
require 'opensearch/dsl/search/sort'
require 'opensearch/dsl/search/options'
require 'opensearch/dsl/search/suggest'

Dir[File.expand_path('dsl/search/queries/**/*.rb', __dir__)].sort.each        { |f| require f }
Dir[File.expand_path('dsl/search/filters/**/*.rb', __dir__)].sort.each        { |f| require f }
Dir[File.expand_path('dsl/search/aggregations/**/*.rb', __dir__)].sort.each   { |f| require f }

require 'opensearch/dsl/search'

module OpenSearch
  # The main module, which can be included into your own class or namespace,
  # to provide the DSL methods.
  #
  # @example
  #
  #     include OpenSearch::DSL
  #
  #     definition = search do
  #       query do
  #         match title: 'test'
  #       end
  #     end
  #
  #     definition.to_hash
  #     # => { query: { match: { title: "test"} } }
  #
  # @see Search
  #
  module DSL
    def self.included(base)
      base.__send__ :include, OpenSearch::DSL::Search
    end
  end
end
