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
        # A query which returns documents matching a specified expression in the Lucene Query String syntax
        #
        # @example
        #
        #     search do
        #       query do
        #         query_string do
        #           query '(mortgage OR (bank AND loan)) AND published_on:[2013-01-01 TO 2013-12-31]'
        #           fields [:title, :content]
        #         end
        #       end
        #     end
        #
        # @see http://lucene.apache.org/core/2_9_4/queryparsersyntax.html
        #
        class QueryString
          include BaseComponent

          option_method :query
          option_method :fields
          option_method :type
          option_method :default_field
          option_method :default_operator
          option_method :analyzer
          option_method :allow_leading_wildcard
          option_method :lowercase_expanded_terms
          option_method :enable_position_increments
          option_method :fuzzy_max_expansions
          option_method :fuzziness
          option_method :fuzzy_prefix_length
          option_method :phrase_slop
          option_method :boost
          option_method :analyze_wildcard
          option_method :auto_generate_phrase_queries
          option_method :minimum_should_match
          option_method :lenient
          option_method :locale
          option_method :use_dis_max
          option_method :tie_breaker
          option_method :time_zone
        end
      end
    end
  end
end
