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
      module Filters
        # A filter which returns documents which fall into a specified geographical polygon
        #
        # @example
        #
        #     search do
        #       query do
        #         filtered do
        #           filter do
        #             geo_polygon :location do
        #               points [
        #                [14.2244355,49.9419006],
        #                [14.2244355,50.1774301],
        #                [14.7067869,50.1774301],
        #                [14.7067869,49.9419006],
        #                [14.2244355,49.9419006]
        #               ]
        #             end
        #           end
        #         end
        #       end
        #     end
        #
        # See the integration test for a working example.
        #
        # @see http://opensearch.org/guide/en/opensearch/reference/current/query-dsl-geo-polygon-filter.html
        #
        class GeoPolygon
          include BaseComponent

          option_method :points
        end
      end
    end
  end
end
