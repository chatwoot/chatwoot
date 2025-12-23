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
        # A filter which returns documents which fall into a "box" of the specified geographical coordinates
        #
        # @example
        #
        #     search do
        #       query do
        #         filtered do
        #           filter do
        #             geo_bounding_box :location do
        #               top_right   "50.1815123678,14.7149200439"
        #               bottom_left "49.9415476869,14.2162566185"
        #             end
        #           end
        #         end
        #       end
        #     end
        #
        # See the integration test for a working example.
        #
        # Use eg. <http://boundingbox.klokantech.com> to visually define the bounding box.
        #
        # @see http://opensearch.org/guide/en/opensearch/guide/current/geo-bounding-box.html
        #
        class GeoBoundingBox
          include BaseComponent

          option_method :top_left
          option_method :bottom_right
          option_method :top_right
          option_method :bottom_left
          option_method :top
          option_method :left
          option_method :bottom
          option_method :right
        end
      end
    end
  end
end
