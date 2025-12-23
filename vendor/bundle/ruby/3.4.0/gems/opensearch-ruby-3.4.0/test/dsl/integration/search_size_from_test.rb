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
    class SizeIntegrationTest < ::OpenSearch::Test::IntegrationTestCase
      include OpenSearch::DSL::Search

      context 'Search results pagination' do
        setup do
          @client.indices.create index: 'test', body: {
            mappings: { properties: { title: { type: 'text', fields: { keyword: { type: 'keyword' } } } } }
          }

          25.times { |i| @client.index index: 'test', id: i, body: { title: "Test #{format('%03d', i)}" } }

          @client.indices.refresh index: 'test'
        end

        should 'find the correct number of documents' do
          response = @client.search index: 'test', body: search {
            query { match title: 'test' }
            size 15
          }.to_hash

          assert_equal 25, response['hits']['total']['value']
          assert_equal 15, response['hits']['hits'].size
        end

        should 'move the offset' do
          response = @client.search index: 'test', body: search {
            query { match(:title) { query 'test' } }
            size 5
            from 5
            sort { by 'title.keyword' }
          }.to_hash

          assert_equal 25, response['hits']['total']['value']
          assert_equal 5,  response['hits']['hits'].size
          assert_equal 'Test 005', response['hits']['hits'][0]['_source']['title']
          assert_equal 'Test 009', response['hits']['hits'][4]['_source']['title']
        end
      end
    end
  end
end
