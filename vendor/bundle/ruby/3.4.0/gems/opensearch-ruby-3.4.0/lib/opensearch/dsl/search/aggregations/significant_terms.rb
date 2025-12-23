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
      module Aggregations
        # A multi-bucket aggregation that returns interesting or unusual occurrences of terms in a set
        #
        # @example
        #
        #     search do
        #       query do
        #         match :title do
        #           query 'fink'
        #         end
        #       end
        #
        #       aggregation :interesting_terms do
        #         significant_terms do
        #           field :body
        #         end
        #       end
        #     end
        #
        # @see http://opensearch.org/guide/en/opensearch/reference/current/search-aggregations-bucket-significantterms-aggregation.html
        #
        class SignificantTerms
          include BaseAggregationComponent

          option_method :field
          option_method :size
          option_method :shard_size
          option_method :min_doc_count
          option_method :shard_min_doc_count
          option_method :include
          option_method :exclude
          option_method :background_filter
          option_method :mutual_information
          option_method :chi_square
          option_method :gnd
        end
      end
    end
  end
end
