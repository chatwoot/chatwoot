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
    class SearchSortTest < ::OpenSearch::Test::UnitTestCase
      subject { OpenSearch::DSL::Search::Sort.new }

      context 'Search sort' do
        should 'add a single field' do
          subject = OpenSearch::DSL::Search::Sort.new :foo
          assert_equal([:foo], subject.to_hash)
        end

        should 'add multiple fields' do
          subject = OpenSearch::DSL::Search::Sort.new %i[foo bar]
          assert_equal(%i[foo bar], subject.to_hash)
        end

        should 'add a field with options' do
          subject = OpenSearch::DSL::Search::Sort.new foo: { order: 'desc', mode: 'avg' }
          assert_equal([{ foo: { order: 'desc', mode: 'avg' } }], subject.to_hash)
        end

        should 'add fields with the DSL method' do
          subject = OpenSearch::DSL::Search::Sort.new do
            by :foo
            by :bar, order: 'desc'
          end

          assert_equal(
            [
              :foo,
              { bar: { order: 'desc' } }
            ], subject.to_hash
          )
        end

        should 'be empty' do
          subject = OpenSearch::DSL::Search::Sort.new
          assert_equal subject.empty?, true
        end

        should 'not be empty' do
          subject = OpenSearch::DSL::Search::Sort.new foo: { order: 'desc' }
          assert_equal subject.empty?, false
        end

        context '#to_hash' do
          should 'not duplicate values when defined by arguments' do
            subject = OpenSearch::DSL::Search::Sort.new foo: { order: 'desc' }
            assert_equal(subject.to_hash, subject.to_hash)
          end

          should 'not duplicate values when defined by a block' do
            subject = OpenSearch::DSL::Search::Sort.new do
              by :foo
            end

            assert_equal(subject.to_hash, subject.to_hash)
          end
        end
      end
    end
  end
end
