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

require_relative '../test_helper'

module OpenSearch
  module Test
    class ChildrenAggregationIntegrationTest < ::OpenSearch::Test::IntegrationTestCase
      include OpenSearch::DSL::Search

      context 'A children aggregation' do
        setup do
          @client.indices.create index: 'articles-and-comments', body: {
            mappings: {
              properties: {
                title: { type: 'text' },
                category: { type: 'keyword' },
                join_field: { type: 'join', relations: { article: 'comment' } },
                author: { type: 'keyword' }
              }
            }
          }

          @client.index index: 'articles-and-comments', id: 1,
                        body: { title: 'A', category: 'one', join_field: 'article' }
          @client.index index: 'articles-and-comments', id: 2,
                        body: { title: 'B', category: 'one', join_field: 'article' }
          @client.index index: 'articles-and-comments', id: 3,
                        body: { title: 'C', category: 'two', join_field: 'article' }

          @client.index index: 'articles-and-comments', routing: '1',
                        body: { author: 'John', join_field: { name: 'comment', parent: 1 } }
          @client.index index: 'articles-and-comments', routing: '1',
                        body: { author: 'Mary', join_field: { name: 'comment', parent: 1 } }
          @client.index index: 'articles-and-comments', routing: '2',
                        body: { author: 'John', join_field: { name: 'comment', parent: 2 } }
          @client.index index: 'articles-and-comments', routing: '2',
                        body: { author: 'Dave', join_field: { name: 'comment', parent: 2 } }
          @client.index index: 'articles-and-comments', routing: '3',
                        body: { author: 'Ruth', join_field: { name: 'comment', parent: 3 } }
          @client.indices.refresh index: 'articles-and-comments'
        end

        should 'return the top commenters per article category' do
          response = @client.search index: 'articles-and-comments', size: 0, body: search {
            aggregation :top_categories do
              terms field: 'category' do
                aggregation :comments do
                  children type: 'comment' do
                    aggregation :top_authors do
                      terms field: 'author'
                    end
                  end
                end
              end
            end
          }.to_hash

          assert_equal 'one', response['aggregations']['top_categories']['buckets'][0]['key']
          assert_equal 3,
                       response['aggregations']['top_categories']['buckets'][0]['comments']['top_authors']['buckets'].size
          assert_equal 'John',
                       response['aggregations']['top_categories']['buckets'][0]['comments']['top_authors']['buckets'][0]['key']
        end
      end
    end
  end
end
