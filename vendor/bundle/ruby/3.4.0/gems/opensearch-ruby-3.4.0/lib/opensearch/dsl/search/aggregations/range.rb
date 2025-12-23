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
        # A multi-bucket aggregation which returns document counts for custom numerical ranges,
        # which define the buckets
        #
        # @example
        #
        #     search do
        #       aggregation :clicks do
        #         range field: 'clicks',
        #               ranges: [
        #                 { to: 10 },
        #                 { from: 10, to: 20 }
        #               ]
        #       end
        #     end
        #
        # @example Using custom names for the ranges
        #
        #     search do
        #       aggregation :clicks do
        #         range do
        #           field 'clicks'
        #           key :low, to: 10
        #           key :mid, from: 10, to: 20
        #         end
        #       end
        #     end
        #
        class Range
          include BaseAggregationComponent

          option_method :field
          option_method :script
          option_method :params
          option_method :keyed

          def key(key, value)
            @hash[name].update(@args) if @args
            @hash[name][:keyed] = true unless @hash[name].key?(:keyed)
            @hash[name][:ranges] ||= []
            @hash[name][:ranges] << value.merge(key: key) unless @hash[name][:ranges].any? { |i| i[:key] == key }
            self
          end
        end
      end
    end
  end
end
