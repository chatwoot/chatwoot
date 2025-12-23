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
    class SearchAggregationTest < ::OpenSearch::Test::UnitTestCase
      subject { OpenSearch::DSL::Search::Aggregation.new }

      context 'Search Aggregation' do
        should 'be serializable to a Hash' do
          assert_equal({}, subject.to_hash)

          subject = OpenSearch::DSL::Search::Aggregation.new
          subject.instance_variable_set(:@value, { foo: 'bar' })
          assert_equal({ foo: 'bar' }, subject.to_hash)
        end

        should 'evaluate the block and return itself' do
          block   = proc { 1 + 1 }
          subject = OpenSearch::DSL::Search::Aggregation.new(&block)

          subject.expects(:instance_eval)
          assert_instance_of OpenSearch::DSL::Search::Aggregation, subject.call
        end

        should 'call the block and return itself' do
          block   = proc { |_s| 1 + 1 }
          subject = OpenSearch::DSL::Search::Aggregation.new(&block)

          block.expects(:call)
          assert_instance_of OpenSearch::DSL::Search::Aggregation, subject.call
        end

        should 'define the value with DSL methods' do
          assert_nothing_raised do
            subject.terms field: 'foo'
            assert_instance_of Hash, subject.to_hash
            assert_equal({ terms: { field: 'foo' } }, subject.to_hash)
          end
        end

        should 'raise an exception for unknown DSL method' do
          assert_raise(NoMethodError) { subject.foofoo }
        end

        should 'return the aggregations' do
          subject.expects(:call)
          subject.instance_variable_set(:@value, mock(aggregations: { foo: 'bar' }))

          subject.aggregations
        end

        should 'define a nested aggregation' do
          subject.instance_variable_set(:@value, mock(aggregation: true))

          subject.aggregation(:foo) { 1 + 1 }
        end

        should 'return a non-hashy value directly' do
          subject.instance_variable_set(:@value, 'FOO')
          assert_equal 'FOO', subject.to_hash
        end

        should 'return an empty Hash when it has no value set' do
          subject.instance_variable_set(:@value, nil)
          assert_equal({}, subject.to_hash)
        end
      end
    end
  end
end
