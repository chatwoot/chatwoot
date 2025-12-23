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
    class HighlightTest < ::OpenSearch::Test::UnitTestCase
      context 'Search highlight' do
        subject { OpenSearch::DSL::Search::Highlight.new }

        should 'take a Hash' do
          subject = OpenSearch::DSL::Search::Highlight.new fields: { 'foo' => {} }, pre_tags: ['*'], post_tags: ['*']

          assert_equal({ fields: { 'foo' => {} }, pre_tags: ['*'], post_tags: ['*'] }, subject.to_hash)
        end

        should 'encode fields as an array' do
          subject.fields %w[foo bar]
          assert_equal({ fields: { foo: {}, bar: {} } }, subject.to_hash)
        end

        should 'encode fields as a Hash' do
          subject.fields foo: { bar: 1 }, xoo: { bar: 2 }
          assert_equal({ fields: { foo: { bar: 1 }, xoo: { bar: 2 } } }, subject.to_hash)
        end

        should 'encode a field' do
          subject.field 'foo'
          assert_equal({ fields: { foo: {} } }, subject.to_hash)
        end

        should 'be additive on multiple calls' do
          subject.fields %w[foo bar]
          subject.field  'bam'
          subject.field  'baz', { xoo: 10 }
          assert_equal({ fields: { foo: {}, bar: {}, bam: {}, baz: { xoo: 10 } } }, subject.to_hash)
        end

        should 'encode pre_tags' do
          subject.pre_tags '*'
          assert_equal({ pre_tags: ['*'] }, subject.to_hash)
        end

        should 'encode post_tags' do
          subject.post_tags '*'
          assert_equal({ post_tags: ['*'] }, subject.to_hash)
        end

        should 'encode pre_tags as an array' do
          subject.pre_tags ['*', '**']
          assert_equal({ pre_tags: ['*', '**'] }, subject.to_hash)
        end

        should 'encode post_tags as an array' do
          subject.post_tags ['*', '**']
          assert_equal({ post_tags: ['*', '**'] }, subject.to_hash)
        end

        should 'encode the encoder option' do
          subject.encoder 'foo'
          assert_equal({ encoder: 'foo' }, subject.to_hash)
        end

        should 'encode the tags_schema option' do
          subject.tags_schema 'foo'
          assert_equal({ tags_schema: 'foo' }, subject.to_hash)
        end

        should 'combine the options' do
          subject.fields %w[foo bar]
          subject.field  'bam'
          subject.pre_tags '*'
          subject.post_tags '*'
          assert_equal({ fields: { foo: {}, bar: {}, bam: {} }, pre_tags: ['*'], post_tags: ['*'] }, subject.to_hash)
        end
      end
    end
  end
end
