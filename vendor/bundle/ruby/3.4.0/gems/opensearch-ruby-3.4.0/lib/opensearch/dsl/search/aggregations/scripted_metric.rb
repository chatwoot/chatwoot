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
        # A metric aggregation which uses scripts for the computation
        #
        # @example
        #
        #     search do
        #       aggregation :clicks_for_one do
        #         scripted_metric do
        #           init_script "_agg['transactions'] = []"
        #           map_script  "if (doc['tags'].value.contains('one')) { _agg.transactions.add(doc['clicks'].value) }"
        #           combine_script "sum = 0; for (t in _agg.transactions) { sum += t }; return sum"
        #           reduce_script "sum = 0; for (a in _aggs) { sum += a }; return sum"
        #         end
        #       end
        #     end
        #
        # @see http://opensearch.org/guide/en/opensearch/reference/current/search-aggregations-metrics-scripted-metric-aggregation.html
        #
        # See the integration test for a full example.
        #
        class ScriptedMetric
          include BaseComponent

          option_method :init_script
          option_method :map_script
          option_method :combine_script
          option_method :reduce_script
          option_method :params
          option_method :lang
        end
      end
    end
  end
end
