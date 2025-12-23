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
    class BaseAggregationComponentTest < ::OpenSearch::Test::UnitTestCase
      context 'BaseAggregationComponent' do
        class DummyAggregationComponent
          include ::OpenSearch::DSL::Search::BaseAggregationComponent
        end

        class ::OpenSearch::DSL::Search::Aggregations::Dummy
          include ::OpenSearch::DSL::Search::BaseAggregationComponent
        end

        subject { DummyAggregationComponent.new }

        should 'return an instance of the aggregation by name' do
          assert_instance_of ::OpenSearch::DSL::Search::Aggregations::Dummy, subject.dummy
        end

        should 'raise an exception when unknown aggregation is called' do
          assert_raise(NoMethodError) { subject.foobar }
        end

        should 'add a nested aggregation' do
          subject.aggregation :inner do
            dummy field: 'foo'
          end

          assert !subject.aggregations.empty?, "#{subject.aggregations.inspect} is empty"

          assert_instance_of OpenSearch::DSL::Search::Aggregation, subject.aggregations[:inner]
          assert_equal({ dummy: { field: 'foo' } }, subject.aggregations[:inner].to_hash)

          assert_equal 'foo', subject.to_hash[:aggregations][:inner][:dummy][:field]
        end
      end
    end
  end
end
