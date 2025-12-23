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
        # A query which returns documents which are similar to the specified text or documents
        #
        # @example Find documents similar to the provided text
        #
        #     search do
        #       query do
        #         more_like_this do
        #           like   ['Eyjafjallajökull']
        #           fields [:title, :abstract, :content]
        #         end
        #       end
        #     end
        #
        #
        # @example Find documents similar to the specified documents
        #
        #     search do
        #       query do
        #         more_like_this do
        #           like   [{_id: 1}, {_id: 2}, {_id: 3}]
        #           fields [:title, :abstract]
        #         end
        #       end
        #     end
        #
        # @see http://opensearch.org/guide/en/opensearch/reference/current/query-dsl-mlt-query.html
        #
        class MoreLikeThis
          include BaseComponent

          # like/unlike is since 2.0.0
          option_method :like
          option_method :unlike

          # before 2.0.0 the following 3 options were available
          option_method :like_text
          option_method :docs
          option_method :ids

          option_method :fields
          option_method :min_term_freq
          option_method :max_query_terms
          option_method :include
          option_method :exclude
          option_method :percent_terms_to_match
          option_method :stop_words
          option_method :min_doc_freq
          option_method :max_doc_freq
          option_method :min_word_length
          option_method :max_word_length
          option_method :boost_terms
          option_method :boost
          option_method :analyzer
        end
      end
    end
  end
end
