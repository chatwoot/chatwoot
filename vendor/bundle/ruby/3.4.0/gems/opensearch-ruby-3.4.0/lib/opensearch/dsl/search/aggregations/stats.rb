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
        # A multi-value metrics aggregation which returns statistical information on numeric values
        #
        # @example Passing the options as a Hash
        #
        #     search do
        #       aggregation :clicks_stats do
        #         stats field: 'clicks'
        #       end
        #     end
        #
        # @example Passing the options as a block
        #
        #     search do
        #       aggregation :clicks_stats do
        #         stats do
        #           field 'clicks'
        #         end
        #       end
        #     end
        #
        #
        class Stats
          include BaseComponent

          option_method :field
          option_method :script
        end
      end
    end
  end
end
