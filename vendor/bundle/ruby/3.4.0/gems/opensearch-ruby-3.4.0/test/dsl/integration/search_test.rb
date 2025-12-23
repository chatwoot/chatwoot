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
    class SearchIntegrationTest < ::OpenSearch::Test::IntegrationTestCase
      include OpenSearch::DSL::Search

      class MySearch
        include OpenSearch::DSL::Search

        def initialize(q)
          @q = q
        end

        def tags
          %w[one two]
        end

        def search_definition
          search do |q|
            q.query do |q|
              q.bool do |q|
                q.must do |q|
                  q.match title: @q
                end
                q.must do |q|
                  q.terms tags: tags
                end
              end
            end
          end
        end
      end

      context 'The Search class' do
        setup do
          @client.indices.create index: 'test'
          @client.index index: 'test', id: '1', body: { title: 'Test', tags: ['one'] }
          @client.index index: 'test', id: '2', body: { title: 'Test', tags: %w[one two] }
          @client.index index: 'test', id: '3', body: { title: 'Test', tags: ['three'] }
          @client.indices.refresh index: 'test'
        end

        should 'have access to the calling context' do
          s = MySearch.new('test')
          response = @client.search index: 'test', body: s.search_definition.to_hash

          assert_equal 2, response['hits']['total']['value']
          assert_equal 'Test', response['hits']['hits'][0]['_source']['title']
          assert_same_elements %w[1 2], response['hits']['hits'].map { |d| d['_id'] }
        end
      end
    end
  end
end
