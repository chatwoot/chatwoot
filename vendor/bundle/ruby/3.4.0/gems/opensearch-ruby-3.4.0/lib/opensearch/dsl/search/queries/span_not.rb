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
        # A query which discards matching documents which overlap with another query
        #
        # @example
        #
        #     search do
        #       query do
        #         span_not include: { span_term: { title: 'disaster' } },
        #                  exclude: { span_term: { title: 'health' } }
        #       end
        #     end
        #
        # @see http://opensearch.org/guide/en/opensearch/reference/current/query-dsl-span-not-query.html
        # @see https://lucene.apache.org/core/5_0_0/core/org/apache/lucene/search/spans/package-summary.html
        #
        class SpanNot
          include BaseComponent

          option_method :include
          option_method :exclude
          option_method :pre
          option_method :post
          option_method :dist
        end
      end
    end
  end
end
