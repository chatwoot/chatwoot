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
        # Given an ordered series of data, the Moving Average aggregation will slide a window across the data and emit the average value of that window.
        #
        # @example Passing the options as a Hash
        #
        #     aggregation :the_movavg do
        #       moving_avg buckets_path: 'the_sum'
        #     end
        #
        # @example Passing the options as a block
        #
        #     aggregation :the_movavg do
        #       moving_avg do
        #         buckets_path 'the_sum'
        #         model 'holt'
        #         window 5
        #         gap_policy 'insert_zero'
        #         settings({ alpha: 0.5 })
        #       end
        #     end
        #
        #
        class MovingAvg
          include BaseAggregationComponent

          option_method :buckets_path
          option_method :model
          option_method :gap_policy
          option_method :window
          option_method :format
          option_method :minimize
          option_method :settings
        end
      end
    end
  end
end
