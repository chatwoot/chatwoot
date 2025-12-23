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
    class GeoAggregationIntegrationTest < ::OpenSearch::Test::IntegrationTestCase
      include OpenSearch::DSL::Search

      context 'A geo aggregation' do
        setup do
          @client.indices.create index: 'venues-test', body: {
            mappings: {
              properties: {
                location: { type: 'geo_point' }
              }
            }
          }
          @client.index index: 'venues-test',
                        body: { name: 'Space', location: '38.886214,1.403889' }
          @client.index index: 'venues-test',
                        body: { name: 'Pacha', location: '38.9184427,1.4433646' }
          @client.index index: 'venues-test',
                        body: { name: 'Amnesia', location: '38.948045,1.408341' }
          @client.index index: 'venues-test',
                        body: { name: 'Privilege', location: '38.958082,1.408288' }
          @client.index index: 'venues-test',
                        body: { name: 'Es Paradis', location: '38.979071,1.307394' }
          @client.indices.refresh index: 'venues-test'
        end

        should 'return the geo distances from a location' do
          response = @client.search index: 'venues-test', size: 0, body: search {
            aggregation :venue_distances do
              geo_distance do
                field  :location
                origin '38.9126352,1.4350621'
                unit   'km'
                ranges [{ to: 1 }, { from: 1, to: 5 }, { from: 5, to: 10 }, { from: 10 }]

                aggregation :top_venues do
                  top_hits _source: { include: 'name' }
                end
              end
            end
          }.to_hash

          result = response['aggregations']['venue_distances']

          assert_equal 4,       result['buckets'].size
          assert_equal 1,       result['buckets'][0]['doc_count']
          assert_equal 'Pacha', result['buckets'][0]['top_venues']['hits']['hits'][0]['_source']['name']

          assert_equal 2,       result['buckets'][1]['top_venues']['hits']['total']['value']
        end

        should 'return the geohash grid distribution' do
          #
          # See the geohash plot eg. at http://openlocation.org/geohash/geohash-js/
          # See the locations visually eg. at http://geohash.org/sncj8h17r2
          #
          response = @client.search index: 'venues-test', size: 0, body: search {
            aggregation :venue_distributions do
              geohash_grid do
                field     :location
                precision 5

                aggregation :top_venues do
                  top_hits _source: { include: 'name' }
                end
              end
            end
          }.to_hash

          result = response['aggregations']['venue_distributions']

          assert_equal 4,       result['buckets'].size
          assert_equal 'sncj8', result['buckets'][0]['key']
          assert_equal 2,       result['buckets'][0]['doc_count']

          assert_same_elements %w[Privilege Amnesia], result['buckets'][0]['top_venues']['hits']['hits'].map { |h|
                                                        h['_source']['name']
                                                      }
        end
      end
    end
  end
end
