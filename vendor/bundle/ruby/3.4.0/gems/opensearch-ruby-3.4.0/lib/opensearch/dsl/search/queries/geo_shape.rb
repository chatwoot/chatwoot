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
        # A query which returns documents which fall into a specified geographical shape
        #
        # @example
        #
        #     search do
        #       query do
        #         geo_shape :location do
        #           shape type: 'envelope',
        #                 coordinates: [[14.2162566185,49.9415476869], [14.7149200439,50.1815123678]]
        #         end
        #       end
        #     end
        #
        #
        class GeoShape
          include BaseComponent

          option_method :shape
          option_method :indexed_shape
        end
      end
    end
  end
end
