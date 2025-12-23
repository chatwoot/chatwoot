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
        # An aggregation which will calculate the smallest bounding box required to encapsulate
        # all of the documents matching the query
        #
        # @example
        #
        #     search do
        #       query do
        #         filtered do
        #           filter do
        #             geo_bounding_box :location do
        #               top_left     "40.8,-74.1"
        #               bottom_right "40.4,-73.9"
        #             end
        #           end
        #         end
        #       end
        #
        #       aggregation :new_york do
        #         geohash_grid field: 'location'
        #       end
        #
        #       aggregation :map_zoom do
        #         geo_bounds field: 'location'
        #       end
        #     end
        #
        # @see http://opensearch.org/guide/en/opensearch/guide/current/geo-bounds-agg.html
        #
        class GeoBounds
          include BaseComponent

          option_method :field
          option_method :wrap_longitude
        end
      end
    end
  end
end
