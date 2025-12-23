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

# encoding: UTF-8

require_relative '../test_helper'

module OpenSearch
  module Test
    class SuggestIntegrationTest < ::OpenSearch::Test::IntegrationTestCase
      include OpenSearch::DSL::Search

      context 'Suggest integration' do
        setup do
          @client.indices.create index: 'test', body: {
            mappings: {
              properties: {
                title: { type: 'text' },
                suggest: {
                  type: 'object',
                  properties: {
                    title: { type: 'completion' },
                    payload: { type: 'object', enabled: false }
                  }
                }
              }
            }
          }

          @client.index index: 'test', id: '1', body: {
            title: 'One',
            suggest: {
              title: { input: %w[one uno jedna] },
              payload: { id: '1' }
            }
          }
          @client.index index: 'test', id: '2', body: {
            title: 'Two',
            suggest: {
              title: { input: %w[two due dvě] },
              payload: { id: '2' }
            }
          }
          @client.index index: 'test', id: '3', body: {
            title: 'Three',
            suggest: {
              title: { input: %w[three tres tři] },
              payload: { id: '3' }
            }
          }
          @client.indices.refresh index: 'test'
        end

        should 'return suggestions' do
          s = search do
            suggest :title, text: 't', completion: { field: 'suggest.title' }
          end

          response = @client.search index: 'test', body: s.to_hash

          assert_equal 2, response['suggest']['title'][0]['options'].size

          assert_same_elements %w[2 3], response['suggest']['title'][0]['options'].map { |d|
                                          d['_source']['suggest']['payload']['id']
                                        }
        end

        should 'return a single suggestion' do
          s = search do
            suggest :title, text: 'th', completion: { field: 'suggest.title' }
          end

          response = @client.search index: 'test', body: s.to_hash

          assert_equal 1, response['suggest']['title'][0]['options'].size

          assert_same_elements %w[3], response['suggest']['title'][0]['options'].map { |d|
                                        d['_source']['suggest']['payload']['id']
                                      }
        end
      end
    end
  end
end
