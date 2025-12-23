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
        # A query which allows to use the `match` query on multiple fields
        #
        # @example
        #
        #     search do
        #       query do
        #         multi_match do
        #           query    'how to fix my printer'
        #           fields   [:title, :abstract, :content]
        #           operator 'and'
        #         end
        #       end
        #     end
        #
        # @see http://opensearch.org/guide/en/opensearch/reference/current/query-dsl-multi-match-query.html
        #
        class MultiMatch
          include BaseComponent

          option_method :analyzer
          option_method :boost
          option_method :cutoff_frequency
          option_method :fields
          option_method :fuzziness
          option_method :max_expansions
          option_method :minimum_should_match
          option_method :operator
          option_method :prefix_length
          option_method :query
          option_method :rewrite
          option_method :slop
          option_method :type
          option_method :use_dis_max
          option_method :zero_terms_query
        end
      end
    end
  end
end
