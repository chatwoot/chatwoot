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
        # A query which executes the search for low frequency terms first, and high frequency ("common")
        # terms second
        #
        # @example
        #
        #     search do
        #       query do
        #         common :body do
        #           query 'shakespeare to be or not to be'
        #         end
        #       end
        #     end
        #
        # This query is frequently used when a stopwords-based approach loses too much recall and/or precision.
        #
        # @see http://opensearch.org/guide/en/opensearch/reference/current/query-dsl-common-terms-query.html
        #
        class Common
          include BaseComponent

          option_method :query
          option_method :cutoff_frequency
          option_method :low_freq_operator
          option_method :minimum_should_match
          option_method :boost
          option_method :analyzer
          option_method :disable_coord
        end
      end
    end
  end
end
