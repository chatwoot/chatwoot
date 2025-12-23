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

class OpenSearch::Transport::Transport::Connections::ConnectionTest < Minitest::Test
  include OpenSearch::Transport::Transport::Connections

  context "Connection" do

    should "be initialized with :host, :connection, and :options" do
      c = Connection.new :host => 'x', :connection => 'y', :options => {}
      assert_equal 'x', c.host
      assert_equal 'y', c.connection
      assert_instance_of Hash, c.options
    end

    should "return full path" do
      c = Connection.new
      assert_equal '_search', c.full_path('_search')
      assert_equal '_search', c.full_path('_search', {})
      assert_equal '_search?foo=bar', c.full_path('_search', {:foo => 'bar'})
      assert_equal '_search?foo=bar+bam', c.full_path('_search', {:foo => 'bar bam'})
    end

    should "return full url" do
      c = Connection.new :host => { :protocol => 'http', :host => 'localhost', :port => '9200' }
      assert_equal 'http://localhost:9200/_search?foo=bar', c.full_url('_search', {:foo => 'bar'})
    end

    should "return full url with credentials" do
      c = Connection.new :host => { :protocol => 'http', :user => 'U', :password => 'P', :host => 'localhost', :port => '9200' }
      assert_equal 'http://U:P@localhost:9200/_search?foo=bar', c.full_url('_search', {:foo => 'bar'})
    end

    should "return full url with escaped credentials" do
      c = Connection.new :host => { :protocol => 'http', :user => 'U$$$', :password => 'P^^^', :host => 'localhost', :port => '9200' }
      assert_equal 'http://U%24%24%24:P%5E%5E%5E@localhost:9200/_search?foo=bar', c.full_url('_search', {:foo => 'bar'})
    end

    should "return full url with path" do
      c = Connection.new :host => { :protocol => 'http', :host => 'localhost', :port => '9200', :path => '/foo' }
      assert_equal 'http://localhost:9200/foo/_search?foo=bar', c.full_url('_search', {:foo => 'bar'})
    end

    should "return right full url with path when path starts with /" do
      c = Connection.new :host => { :protocol => 'http', :host => 'localhost', :port => '9200', :path => '/foo' }
      assert_equal 'http://localhost:9200/foo/_search?foo=bar', c.full_url('/_search', {:foo => 'bar'})
    end

    should "have a string representation" do
      c = Connection.new :host => 'x'
      assert_match(/host: x/, c.to_s)
      assert_match(/alive/,   c.to_s)
    end

    should "not be dead by default" do
      c = Connection.new
      assert ! c.dead?
    end

    should "be dead when marked" do
      c = Connection.new.dead!
      assert c.dead?
      assert_equal 1, c.failures
      assert_in_delta c.dead_since, Time.now, 1
    end

    should "be alive when marked" do
      c = Connection.new.dead!
      assert c.dead?
      assert_equal 1, c.failures
      assert_in_delta c.dead_since, Time.now, 1

      c.alive!
      assert ! c.dead?
      assert_equal 1, c.failures
    end

    should "be healthy when marked" do
      c = Connection.new.dead!
      assert c.dead?
      assert_equal 1, c.failures
      assert_in_delta c.dead_since, Time.now, 1

      c.healthy!
      assert ! c.dead?
      assert_equal 0, c.failures
    end

    should "be resurrected if timeout passed" do
      c = Connection.new.dead!

      now = Time.now + 60
      Time.stubs(:now).returns(now)

      assert   c.resurrect!, c.inspect
      assert ! c.dead?,      c.inspect
    end

    should "be resurrected if timeout passed for multiple failures" do
      c = Connection.new.dead!.dead!

      now = Time.now + 60*2
      Time.stubs(:now).returns(now)

      assert   c.resurrect!, c.inspect
      assert ! c.dead?,      c.inspect
    end

    should "implement the equality operator" do
      c1 = Connection.new(:host => { :protocol => 'http', :host => 'foo', :port => 123 })
      c2 = Connection.new(:host => { :protocol => 'http', :host => 'foo', :port => 123 })
      c3 = Connection.new(:host => { :protocol => 'http', :host => 'foo', :port => 456 })

      assert c1 == c2, "Connection #{c1} should be equal to #{c2}"
      assert c2 != c3, "Connection #{c2} should NOT be equal to #{c3}"
    end

  end

end
