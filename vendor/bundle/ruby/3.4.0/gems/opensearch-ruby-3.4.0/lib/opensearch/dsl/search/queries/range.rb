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
        # A query which returns documents matching the specified range
        #
        # @example Find documents within a numeric range
        #
        #     search do
        #       query do
        #         range :age do
        #           gte 10
        #           lte 20
        #         end
        #       end
        #     end
        #
        # @example Find documents published within a date range
        #
        #     search do
        #       query do
        #         range :published_on do
        #           gte '2013-01-01'
        #           lte 'now'
        #           time_zone '+1:00'
        #         end
        #       end
        #     end
        #
        #
        class Range
          include BaseComponent

          option_method :gte
          option_method :gt
          option_method :lte
          option_method :lt
          option_method :boost
          option_method :time_zone
          option_method :format
        end
      end
    end
  end
end
