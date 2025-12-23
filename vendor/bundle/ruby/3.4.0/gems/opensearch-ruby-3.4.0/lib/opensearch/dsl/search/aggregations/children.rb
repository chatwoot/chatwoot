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
        # A single-bucket aggregation which allows to aggregate from buckets on parent documents
        # to buckets on the children documents
        #
        # @example Return the top commenters per article category
        #
        #     search do
        #       aggregation :top_categories do
        #         terms field: 'category' do
        #           aggregation :comments do
        #             children type: 'comment' do
        #               aggregation :top_authors do
        #                 terms field: 'author'
        #               end
        #             end
        #           end
        #         end
        #       end
        #     end
        #
        #
        # See the integration test for a full example.
        #
        # @see http://opensearch.org/guide/en/opensearch/reference/current/search-aggregations-bucket-children-aggregation.html
        #
        class Children
          include BaseAggregationComponent

          option_method :type
        end
      end
    end
  end
end
