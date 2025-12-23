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
        # A parent pipeline aggregation which executes a script which can perform per bucket computations on specified metrics in the parent multi-bucket aggregation.
        #
        # @example Passing the options as a Hash
        #
        #     aggregation :t-shirt-percentage do
        #       bucket_script buckets_path: { tShirtSales: 't-shirts>sales', totalSales: 'total_sales' }, script: 'tShirtSales / totalSales * 100'
        #     end
        #
        # @example Passing the options as a block
        #
        #     aggregation :t-shirt-percentage do
        #       bucket_script do
        #         buckets_path tShirtSales: 't-shirts>sales', totalSales: 'total_sales'
        #         script 'tShirtSales / totalSales * 100'
        #       end
        #     end
        #
        #
        class BucketScript
          include BaseAggregationComponent

          option_method :buckets_path
          option_method :script
          option_method :gap_policy
          option_method :format
        end
      end
    end
  end
end
