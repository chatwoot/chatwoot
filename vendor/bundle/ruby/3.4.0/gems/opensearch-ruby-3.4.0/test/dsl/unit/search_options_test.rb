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
    class SearchOptionsTest < ::OpenSearch::Test::UnitTestCase
      subject { OpenSearch::DSL::Search::Options.new }

      context 'Search options' do
        should 'combine different options' do
          subject.version true
          subject.min_score 0.5

          assert_equal({ version: true, min_score: 0.5 }, subject.to_hash)
        end

        should 'encode _source' do
          subject._source false
          assert_equal({ _source: false }, subject.to_hash)

          subject._source 'foo.*'
          assert_equal({ _source: 'foo.*' }, subject.to_hash)

          subject._source %w[foo bar]
          assert_equal({ _source: %w[foo bar] }, subject.to_hash)

          subject._source include: ['foo.*'], exclude: ['bar.*']
          assert_equal({ _source: { include: ['foo.*'], exclude: ['bar.*'] } }, subject.to_hash)

          subject.source false
          assert_equal({ _source: false }, subject.to_hash)
        end

        should 'encode fields' do
          subject.fields ['foo']
          assert_equal({ fields: ['foo'] }, subject.to_hash)
        end

        should 'encode script_fields' do
          subject.script_fields ['foo']
          assert_equal({ script_fields: ['foo'] }, subject.to_hash)
        end

        should 'encode fielddata_fields' do
          subject.fielddata_fields ['foo']
          assert_equal({ fielddata_fields: ['foo'] }, subject.to_hash)
        end

        should 'encode rescore' do
          subject.rescore foo: 'bar'
          assert_equal({ rescore: { foo: 'bar' } }, subject.to_hash)
        end

        should 'encode explain' do
          subject.explain true
          assert_equal({ explain: true }, subject.to_hash)
        end

        should 'encode version' do
          subject.version true
          assert_equal({ version: true }, subject.to_hash)
        end

        should 'encode track_total_hits' do
          subject.track_total_hits 123
          assert_equal({ track_total_hits: 123 }, subject.to_hash)

          subject.track_total_hits true
          assert_equal({ track_total_hits: true }, subject.to_hash)
        end

        should 'encode indices_boost' do
          subject.indices_boost foo: 'bar'
          assert_equal({ indices_boost: { foo: 'bar' } }, subject.to_hash)
        end

        should 'encode track_scores' do
          subject.track_scores true
          assert_equal({ track_scores: true }, subject.to_hash)
        end

        should 'encode min_score' do
          subject.min_score 0.5
          assert_equal({ min_score: 0.5 }, subject.to_hash)
        end
      end
    end
  end
end
