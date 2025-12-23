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
    class SearchQueryTest < ::OpenSearch::Test::UnitTestCase
      subject { OpenSearch::DSL::Search::Query.new }

      context 'Search Query' do
        should 'be serializable to a Hash' do
          assert_equal({}, subject.to_hash)

          subject = OpenSearch::DSL::Search::Query.new
          subject.instance_variable_set(:@value, {})
          assert_equal({}, subject.to_hash)
        end

        should 'evaluate the block and return itself' do
          block   = proc { 1 + 1 }
          subject = OpenSearch::DSL::Search::Query.new(&block)

          subject.expects(:instance_eval)
          assert_instance_of OpenSearch::DSL::Search::Query, subject.call
        end

        should 'call the block and return itself' do
          block   = proc { |_s| 1 + 1 }
          subject = OpenSearch::DSL::Search::Query.new(&block)

          block.expects(:call)
          assert_instance_of OpenSearch::DSL::Search::Query, subject.call
        end

        should 'define the value with query methods' do
          assert_nothing_raised do
            subject.match foo: 'bar'
            assert_instance_of Hash, subject.to_hash
            assert_equal({ match: { foo: 'bar' } }, subject.to_hash)
          end
        end

        should 'redefine the value with query methods' do
          assert_nothing_raised do
            subject.match foo: 'bar'
            subject.match foo: 'bam'
            subject.to_hash
            subject.to_hash
            assert_instance_of Hash, subject.to_hash
            assert_equal({ match: { foo: 'bam' } }, subject.to_hash)
          end
        end

        should 'have the query methods' do
          assert_nothing_raised { subject.match foo: 'bar' }
        end

        should 'raise an exception for unknown query' do
          assert_raise(NoMethodError) { subject.foofoo }
        end
      end
    end
  end
end
