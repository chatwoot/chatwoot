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
        #
        # A multi-bucket aggregation that creates composite buckets from different sources.
        #
        # @example
        #
        #  search do
        #    aggregation :things do
        #      composite do
        #        size 2000
        #        sources [
        #          { thing1: { terms: { field: 'thing1.field1' } } },
        #          { thing2: { terms: { field: 'thing2.field2' } } }
        #        ]
        #        after after_key
        #      end
        #    end
        #  end
        #
        #
        class Composite
          include BaseAggregationComponent

          option_method :size
          option_method :sources
          option_method :after

          def to_hash(_options = {})
            super
            # remove :after if no value is given
            @hash[name.to_sym].delete(:after) if @hash[name.to_sym].is_a?(Hash) && @hash[name.to_sym][:after].nil?

            @hash
          end
        end
      end
    end
  end
end
