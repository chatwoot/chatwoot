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
  module DSL
    module Search
      module Queries
        # A query which returns documents matching a simplified query string syntax
        #
        # @example
        #
        #     search do
        #       query do
        #         simple_query_string do
        #           query  'disaster -health'
        #           fields ['title^5', 'abstract', 'content']
        #           default_operator 'and'
        #         end
        #       end
        #     end
        #
        # @see http://opensearch.org/guide/en/opensearch/reference/current/query-dsl-simple-query-string-query.html
        #
        class SimpleQueryString
          include BaseComponent

          option_method :query
          option_method :fields
          option_method :default_operator
          option_method :analyzer
          option_method :flags
          option_method :analyze_wildcard
          option_method :lenient
          option_method :minimum_should_match
          option_method :quote_field_suffix
          option_method :all_fields
        end
      end
    end
  end
end
