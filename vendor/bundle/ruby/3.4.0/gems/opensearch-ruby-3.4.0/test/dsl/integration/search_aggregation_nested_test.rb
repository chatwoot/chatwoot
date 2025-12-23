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
    class NestedAggregationIntegrationTest < ::OpenSearch::Test::IntegrationTestCase
      include OpenSearch::DSL::Search

      context 'A nested aggregation' do
        setup do
          @client.indices.create index: 'products-test', body: {
            mappings: {
              properties: {
                title: { type: 'text' },
                category: { type: 'keyword' },
                offers: {
                  type: 'nested',
                  properties: {
                    name: { type: 'text' },
                    price: { type: 'double' }
                  }
                }
              }
            }
          }

          @client.index index: 'products-test',
                        body: { title: 'A',
                                category: 'audio',
                                offers: [{ name: 'A1', price: 100 }, { name: 'A2', price: 120 }] }
          @client.index index: 'products-test',
                        body: { title: 'B',
                                category: 'audio',
                                offers: [{ name: 'B1', price: 200 }, { name: 'B2', price: 180 }] }
          @client.index index: 'products-test',
                        body: { title: 'C',
                                category: 'video',
                                offers: [{ name: 'C1', price: 300 }, { name: 'C2', price: 350 }] }
          @client.indices.refresh index: 'products-test'
        end

        should 'return the minimal price from offers' do
          response = @client.search index: 'products-test', body: search {
            query { match title: 'A' }

            aggregation :offers do
              nested do
                path 'offers'
                aggregation :min_price do
                  min field: 'offers.price'
                end
              end
            end
          }.to_hash

          assert_equal 100, response['aggregations']['offers']['min_price']['value'].to_i
        end

        should 'return the top categories for offer price range' do
          response = @client.search index: 'products-test', body: search {
            query do
              bool do
                must do
                  nested do
                    path 'offers'
                    query do
                      bool do
                        filter do
                          range 'offers.price' do
                            gte 100
                            lte 300
                          end
                        end
                      end
                    end
                  end
                end
              end
            end

            aggregation :offers do
              nested do
                path 'offers'
                aggregation :top_categories do
                  reverse_nested do
                    aggregation :top_category_per_offer do
                      terms field: 'category'
                    end
                  end
                end
              end
            end
          }.to_hash

          assert_equal 2, response['aggregations']['offers']['top_categories']['top_category_per_offer']['buckets'].size
          assert_equal 'audio',
                       response['aggregations']['offers']['top_categories']['top_category_per_offer']['buckets'][0]['key']
          assert_equal 'video',
                       response['aggregations']['offers']['top_categories']['top_category_per_offer']['buckets'][1]['key']
        end
      end
    end
  end
end
