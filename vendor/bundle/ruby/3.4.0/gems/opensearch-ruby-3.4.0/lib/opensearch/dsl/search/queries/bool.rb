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
        # A compound query which matches documents based on combinations of queries
        #
        # @example Defining a bool query with multiple conditions
        #
        #     search do
        #       query do
        #         bool do
        #           must do
        #             term category: 'men'
        #           end
        #
        #           must do
        #             term size:  'xxl'
        #           end
        #
        #           should do
        #             term color: 'red'
        #           end
        #
        #           must_not do
        #             term manufacturer: 'evil'
        #           end
        #         end
        #       end
        #     end
        #
        # See the integration test for a working example.
        #
        # @see http://opensearch.org/guide/en/opensearch/reference/current/query-dsl-bool-query.html
        #
        class Bool
          include BaseComponent

          option_method :minimum_should_match
          option_method :boost

          def must(*args, &block)
            @hash[name][:must] ||= []
            value = args.empty? ? Query.new(*args, &block).to_hash : args.first.to_hash
            @hash[name][:must].push(value).flatten! unless @hash[name][:must].include?(value)
            self
          end

          def must_not(*args, &block)
            @hash[name][:must_not] ||= []
            value = args.empty? ? Query.new(*args, &block).to_hash : args.first.to_hash
            @hash[name][:must_not].push(value).flatten! unless @hash[name][:must_not].include?(value)
            self
          end

          def should(*args, &block)
            @hash[name][:should] ||= []
            value = args.empty? ? Query.new(*args, &block).to_hash : args.first.to_hash
            @hash[name][:should].push(value).flatten! unless @hash[name][:should].include?(value)
            self
          end

          def filter(*args, &block)
            @hash[name][:filter] ||= []
            if (filter = block ? Filter.new(*args, &block) : args.first)
              @hash[name][:filter] << filter.to_hash
            end
            self
          end

          def to_hash
            @hash[name].update(@args.to_hash) if @args.respond_to?(:to_hash)

            if @block
              call
            else
              @hash[name] = @args unless @args.nil? || @args.empty?
            end
            @hash
          end
        end
      end
    end
  end
end
