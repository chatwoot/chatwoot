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
        # A query which will score the documents based on the highest score of any individual specified query,
        # not by summing the scores (as eg. a `bool` query would)
        #
        # @example
        #
        #     search do
        #       query do
        #         dis_max do
        #           queries [
        #            { match: { title:   'albino' } },
        #            { match: { content: 'elephant' } }
        #           ]
        #         end
        #       end
        #     end
        #
        # @see http://opensearch.org/guide/en/opensearch/guide/current/_best_fields.html
        #
        class DisMax
          include BaseComponent

          option_method :queries
          option_method :boost
          option_method :tie_breaker
        end
      end
    end
  end
end
