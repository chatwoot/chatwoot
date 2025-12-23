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
    class QueryIntegrationTest < ::OpenSearch::Test::IntegrationTestCase
      include OpenSearch::DSL::Search

      context 'Queries integration' do
        setup do
          @client.indices.create index: 'test'
          @client.index index: 'test', id: '1', body: { title: 'Test', tags: ['one'] }
          @client.index index: 'test', id: '2', body: { title: 'Rest', tags: %w[one two] }
          @client.indices.refresh index: 'test'
        end

        context 'for match query' do
          should 'find the document' do
            response = @client.search index: 'test', body: search { query { match title: 'test' } }.to_hash

            assert_equal 1, response['hits']['total']['value']
          end
        end

        context 'for match_phrase_prefix query' do
          should 'find the document' do
            response = @client.search index: 'test', body: search { query { match_phrase_prefix title: 'te' } }.to_hash

            assert_equal 1, response['hits']['total']['value']
          end
        end

        context 'for query_string query' do
          should 'find the document' do
            response = @client.search index: 'test', body: search { query { query_string { query 'te*' } } }.to_hash

            assert_equal 1, response['hits']['total']['value']
          end
        end

        context 'for the bool query' do
          should 'find the document' do
            response = @client.search index: 'test', body: search {
                                                             query do
                                                               bool do
                                                                 must   { terms tags: ['one'] }
                                                                 should { match title: 'Test' }
                                                               end
                                                             end
                                                           }.to_hash

            assert_equal 2, response['hits']['total']['value']
            assert_equal 'Test', response['hits']['hits'][0]['_source']['title']
          end

          should 'find the document with a filter' do
            response = @client.search index: 'test', body: search {
                                                             query do
                                                               bool do
                                                                 filter  { terms tags: ['one'] }
                                                                 filter  { terms tags: ['two'] }
                                                               end
                                                             end
                                                           }.to_hash

            assert_equal 1, response['hits']['total']['value']
            assert_equal 'Rest', response['hits']['hits'][0]['_source']['title']
          end
        end
      end
    end
  end
end
